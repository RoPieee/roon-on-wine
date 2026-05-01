# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A shell-driven installer that runs Roon (a Windows-only .NET audio player) on Linux/FreeBSD via Wine. There is no application code — the deliverable is two scripts (`install.sh`, generated `start_my_roon_instance.sh`) plus a small C-language Wine DLL proxy used to work around a Wine bug.

This is a fork of upstream `RoPieee/roon-on-wine`. See [PR #49](https://github.com/RoPieee/roon-on-wine/pull/49). The fork-specific value is the WMI crash fix and a few QoL tweaks; understand the upstream baseline before changing install flow.

## Common commands

```bash
./install.sh                      # one-shot: wipe ~/my_roon_instance prefix, install .NET 7 + .NET 4.7.2 + Roon, build start script
./start_my_roon_instance.sh       # launch Roon (runs against ~/my_roon_instance)
VERBOSE=1 ./install.sh            # show winetricks/wine output (default suppresses to /dev/null)
```

There is no test suite, no linter, no CI config. The `winetricks` script in the repo root is downloaded fresh by `install.sh` (it's gitignored) — do not edit it as project source.

### Rebuilding the proxy DLL

```bash
make            # build wminet_utils.dll via x86_64-w64-mingw32-gcc
make verify     # build + assert it's a valid x86_64 PE32+ DLL
make clean      # remove build artifact
```

Requires `mingw-w64` (Arch: `pacman -S mingw-w64-gcc`). Verified rebuilds produce a binary with **identical export tables** to the committed `wminet_utils.dll` — only the PE timestamp differs. If you regenerate, restore the committed binary unless you intentionally want to bump the timestamp; otherwise you'll commit a no-op binary diff.

The committed binary is x86_64 only — `install.sh` will refuse to run with `WINE_PLATFORM=win32`.

## Architecture

### Two-stage execution model

1. **`install.sh`** runs once on the host. It:
   - Downloads `winetricks` and the Roon installer
   - Wipes and recreates the Wine prefix at `$HOME/my_roon_instance` (configurable via `WIN_ROON_DIR`)
   - Installs **.NET 7 runtime via winetricks** then **.NET 4.7.2 from the bundled `NDP472-KB4054530-x86-x64-AllOS-ENU.exe`** — order matters; doing 4.7.2 first or via winetricks fails on many distros (see commented-out alternates in `install.sh:99-108`)
   - Sets winetricks knobs: `win10`, `ddr=opengl`, `sound=alsa`, `nocrashdialog`
   - Installs the WMI crash fix (see below)
   - Detects Roon's `LocalAppData` path by running `cmd.exe /c echo %LocalAppData%` inside Wine and converting via `winepath -u`
   - Generates `start_my_roon_instance.sh` from a heredoc, baking in the discovered path and the auto-detected display scale
   - Sets Roon's theme to Dark by writing `Roon/Settings/theme`
   - Installs XDG `.desktop` file + icons

2. **`start_my_roon_instance.sh`** is the generated artifact. It only sets env vars and execs `wine Roon.exe -scalefactor=$SCALEFACTOR`. **It is gitignored** — anything you want preserved across reinstalls must live in the `_EOF_` heredoc inside `install.sh` (see `install.sh:221-240`). Past breakage: env vars added to the shipped `start_my_roon_instance.sh` were lost on reinstall because they weren't in the template (commit `6a89bb5`).

### The WMI crash fix (the reason this fork exists)

Roon ≥ 2.65 calls `wminet_utils.dll.GetErrorInfo` via `System.Management.WbemErrorInfo`. Wine's built-in stub aborts the process. The fix is a **prefix-local DLL proxy**, installed by `_install_wminet_proxy()` in `install.sh:140-189`:

- `src/wminet_utils_proxy.c` defines `GetErrorInfo` as a no-op returning `S_FALSE`.
- `src/wminet_utils.def` re-exports the other 65 symbols by **aliasing** to `wminet_utils_wine.<name>` — i.e. they forward to a renamed copy of the original Wine DLL. Total = 66 exports; only `GetErrorInfo` is local.
- `_install_wminet_proxy` searches `/usr/lib/wine`, `/usr/lib32/wine`, `/usr/lib64/wine`, `/opt/wine-*/lib/wine` for `x86_64-windows/wminet_utils.dll`, copies it as `wminet_utils_wine.dll` into the prefix's `system32`, drops our proxy alongside as `wminet_utils.dll`, and sets `HKCU\Software\Wine\DllOverrides\wminet_utils=native` so Wine loads the proxy.
- The function is fail-closed: any error (Wine DLL missing, bundled proxy missing, `cp` failed, registry write failed) returns non-zero, and the call site at `install.sh:190-194` aborts the install with a clear message rather than producing a silently broken start script.

Earlier commits (`28c43ed`, `dce6fe5`) tried system-wide DLL replacement and `WINEDLLOVERRIDES`; both are obsolete. **Do not regress to those approaches** — the prefix-local registry override is intentional (no sudo, no system file changes, only affects this one prefix).

When changing the proxy: every Wine release may add or rename exports in the upstream `wminet_utils.dll`. If users hit `unimplemented function` errors after a Wine upgrade, regenerate `src/wminet_utils.def` from the new Wine DLL's exports (`x86_64-w64-mingw32-objdump -p $WINE_LIB | sed -n '/Export Address Table/,/^$/p'`), keeping `GetErrorInfo` as the only line without `= wminet_utils_wine.<name>`. Then `make` to rebuild.

### Generated start-script env contract

The heredoc at `install.sh:221-240` is the **single source of truth** for runtime env. Current contents:

| Var | Purpose |
|---|---|
| `WINEFSYNC=1` + `WINEFSYNC_SPINCOUNT=2000` | fsync sync primitives, reduces audio glitches |
| `WINEDEBUG=-all` | suppress Wine warnings (high CPU otherwise) |
| `WINEDLLOVERRIDES="windows.media.mediacontrol="` | disable a stub that Roon probes |
| `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` | avoid ICU dependency |
| `__GL_SHADER_DISK_CACHE=1` + `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` | persistent OpenGL shader cache (NVIDIA) |
| `-scalefactor=$SCALEFACTOR` | Roon CLI flag, value baked from `hyprctl monitors` if available |

If you add a new env var, add it to the **heredoc**, not the generated file.

### Auto-scale detection

`install.sh:209-216` shells out to `hyprctl monitors` and parses the first `scale:` line. Empty/`0.0` results are clamped to `1.0` via a `case` statement. Falls back to `1.0` for non-Hyprland systems. Users can hand-edit `SCALEFACTOR=` in the generated script.

## Conventions and gotchas

- **`*.exe` is gitignored** but the repo intentionally tracks two large EXEs in the root (`RoonInstaller64.exe` 158MB, `NDP472-KB4054530-x86-x64-AllOS-ENU.exe` 80MB). Don't `git add -A` blindly; they're tracked because `install.sh` falls back to them when the wget download is skipped.
- **Wine prefix is `$HOME/my_roon_instance`**, not `~/.wine`. Don't use `WINEPREFIX=~/.wine` — the install script wipes its target prefix on every run.
- **`winetricks` script is committed in the repo root** but also gitignored and re-downloaded by `install.sh` — the committed copy is for offline installs / fallback. Don't manually update it.
- **FreeBSD support is a contract**: `install.sh` shebang is `#!/usr/bin/env bash` (commit `0e195f0`) specifically for FreeBSD path compatibility. Don't change to `#!/bin/bash`.
- **The commented-out winetricks `dotnetXX` lines in `install.sh:99-108` are documentation**, not dead code — they record which combinations have been tried and failed across distros. Keep them.

## Branch state (at fork point)

This repo is on `fix/wminet-utils-geterrorinfo-crash`. Master tracks upstream; the fork's commits live on this branch. PRs back to upstream should target `RoPieee/roon-on-wine#master`.
