# Running Roon on Linux with Wine

This script makes it possible to run Roon on Wine. It creates a separate Wine instance in a folder; this is required for Roon.

## Why this fork exists

Roon 2.65 (build 1653) introduced WMI volume enumeration (`VolumeAttached.GetInfoFromDrive`) that calls Wine's unimplemented `wminet_utils.dll.GetErrorInfo`, causing a hard crash at startup (`wine: Call from ... to unimplemented function wminet_utils.dll.GetErrorInfo, aborting`).

**Upstream is currently broken for all Roon ≥ 2.65 users.**

This fork fixes the crash and adds quality-of-life improvements:

| Change | Detail |
|--------|--------|
| **WMI crash fix** | Prefix-local proxy `wminet_utils.dll` stubs `GetErrorInfo` as a no-op, converting the abort into a catchable .NET exception. No sudo, no system file changes — only affects the Roon Wine prefix. |
| **Auto-scale** | Detects display scaling from Hyprland (or falls back to 1.0) instead of hardcoding `SCALEFACTOR=1.0` |
| **Dark theme** | Sets Roon to dark theme by default |
| **Performance** | `WINEFSYNC=1`, shader disk cache, fsync spincount, ClearType font smoothing, DPI-aware rendering, instant menus |

See [PR #49](https://github.com/RoPieee/roon-on-wine/pull/49) for the upstream contribution.

---

Right now the script is very rudimentary: more stuff is coming soon. Keep in mind that you need the following programs to be installed on your Linux/FreeBSD system:

* wine
* winetricks
* winecfg
* wget

## Wine version

With respect to which version of Wine... this is a bit 'hit-and-miss'. 

# Install 
To install Roon just clone or download this repository and run <code>./install.sh</code>

Be patient, as installing the necessary components for Wine can take some time. Don't be scared of the messages that flood the console: drink a coffee and wait...

The installation is basically unattended. When the Roon installer starts you will need to click 'Install'.

When finished you can start Roon with <code>./start_my_roon_instance.sh</code>

## UI scaling
The scaling factor is auto-detected from your display settings (Hyprland monitor scale). You can manually override it by editing `SCALEFACTOR` in `start_my_roon_instance.sh`.
* Sensible values are between 1.0 and 2.0

# Supported distro's
This scripts has been reported to work on:

* ArchLinux
* KDE Neon
* openSUSE
* Fedora
  * Don't use the WineHQ repo, but just the Fedora-native Wine (<code>sudo dnf install wine</code>)
* Ubuntu
* Linux Mint

Other OS:

* FreeBSD

<b> Ubuntu 20.04 (Focal Fossa) / Linux Mint 20x requires at least 'winehq-stable' (wine version 7.0+) or 'winehq-staging' (wine version 7.22+) </b>

If your distro is missing please leave a note!
