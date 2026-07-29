#!/usr/bin/env bash

#set -x
WIN_ROON_DIR=my_roon_instance
ROON_DOWNLOAD=http://download.roonlabs.com/builds/RoonInstaller64.exe
WINETRICKS_DOWNLOAD=https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
WINE_PLATFORM="${WINE_PLATFORM:-win64}"
VERBOSE=0

# Single source of truth for Wine DLL search paths — used by both the discovery
# loop and the error message in _install_wminet_proxy.
WINE_LIB_DIRS=(
    /usr/lib/wine
    /usr/lib32/wine
    /usr/lib64/wine
    /usr/lib/x86_64-linux-gnu/wine    # Debian/Ubuntu multiarch
    /opt/wine-stable/lib/wine
    /opt/wine-devel/lib/wine
    /opt/wine-staging/lib/wine
)

# This fork's wminet_utils proxy DLL is built x86_64-only. 32-bit Wine prefixes
# are not supported — Roon 2.65+ would crash without the proxy and we have no
# 32-bit binary to ship. If you need win32 support, build src/ for i686 and
# adjust _install_wminet_proxy to pick i386-windows.
if [ "$WINE_PLATFORM" = "win32" ]; then
    echo "ERROR: win32 Wine prefixes are not supported by this fork."
    echo "       The bundled wminet_utils.dll proxy is x86_64-only."
    exit 1
fi

PREFIX="$HOME/$WIN_ROON_DIR"

_check_for_executable()
{
   local exe=$1

   if ! type $exe >/dev/null 2>&1
   then
      echo "ERROR: can't find $exe, which is required for Roon installation."
      echo "Please install $exe using your distribution package tooling."
      echo
      exit 1

   fi
}

_winepath()
{
   env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX winepath "$@"

   sleep 2
}

_winetricks()
{
   comment="$1"
   shift
   echo "[${WINE_PLATFORM}|${PREFIX}] $comment ..."
   if [ $VERBOSE -eq 1 ]
   then
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX ./winetricks "$@"
   else
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX ./winetricks "$@" >/dev/null 2>&1
   fi

   sleep 2
}

_wine()
{
   comment="$1"
   shift

   # Require this clause for determing LocalAppData path properly. 
   # The comment would be included in the path; otherwise
   if [ ${#comment} -gt 0 ]
   then
      echo "[${WINE_PLATFORM}|${PREFIX}] $comment ..."
   fi

   if [ $VERBOSE -eq 1 ]
   then
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX WINEDLLOVERRIDES=winemenubuilder.exe=d wine "$@"
   else
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX WINEDLLOVERRIDES=winemenubuilder.exe=d wine "$@" 2>/dev/null
   fi

   sleep 2
}



# download winetricks
rm -f ./winetricks
wget $WINETRICKS_DOWNLOAD
chmod +x ./winetricks

# check necessary stuff
_check_for_executable wine
_check_for_executable winecfg
_check_for_executable ./winetricks
_check_for_executable wget

# configure Wine
rm -rf $HOME/$WIN_ROON_DIR
_wine "Setup Wine bottle" wineboot --init

# installing .NET needs to be done in a few steps; if we do this at once it fails on a few systems

#_winetricks "Installing .NET 2.0"   -q dotnet20
#_winetricks "Installing .NET 3.0"   -q dotnet30sp1
#_winetricks "Installing .NET 3.5"   -q dotnet35
#_winetricks "Installing .NET 4.0"    -q --force dotnet40
#_winetricks "Installing .NET 4.5"    -q --force dotnet45
#_winetricks "Installing .NET 4.5.2"  -q --force dotnet452
#_winetricks "Installing .NET 4.6.2" -q dotnet462
#_winetricks "Installing .NET 4.7.2" -q dotnet472
#_winetricks "Installing .NET 4.8" -q dotnet48
#_winetricks "Installing .NET 6.0 Runtime" -q dotnet6
_winetricks "Installing .NET 7.0 Runtime" -q dotnet7

# setting some environment stuff
_winetricks "Setting Windows version to 10" -q win10
_winetricks "Setting DDR to OpenGL"         -q ddr=opengl
_winetricks "Setting sound to ALSA"         -q sound=alsa
_winetricks "Disabling crash dialog"        -q nocrashdialog

# Download and install .NET 4.8 using offline installer
#rm -f ./NDP48-x86-x64-AllOS-ENU.exe
#wget 'https://download.visualstudio.microsoft.com/download/pr/2d6bb6b2-226a-4baa-bdec-798822606ff1/8494001c276a4b96804cde7829c04d7f/ndp48-x86-x64-allos-enu.exe' -O ./NDP48-x86-x64-ALLOS-ENU.exe
#_wine "Installing .NET..." ./NDP48-x86-x64-ALLOS-ENU.exe /q

rm -f ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe
# wget 'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
wget 'https://download.visualstudio.microsoft.com/download/pr/1f5af042-d0e4-4002-9c59-9ba66bcf15f6/089f837de42708daacaae7c04b7494db/ndp472-kb4054530-x86-x64-allos-enu.exe' -O ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe
_wine "Installing .NET" ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe /q

sleep 2

# download Roon
rm -rf $ROON_DOWNLOAD
test -f $( basename $ROON_DOWNLOAD ) || wget $ROON_DOWNLOAD

# install Roon
_wine "Installing Roon" $( basename $ROON_DOWNLOAD  )

# Install wminet_utils proxy DLL (Wine-prefix-local, no sudo required)
# Roon 2.65+ calls GetErrorInfo via WMI — an unimplemented Wine stub that aborts.
# We place a proxy DLL + renamed original in this prefix's system32, and set a
# registry override so Wine loads the proxy instead of the built-in stub.
_install_wminet_proxy()
{
    local wine_lib=""
    local script_dir d candidate sys32
    script_dir="$(cd "$(dirname "$0")" && pwd)"

    for d in "${WINE_LIB_DIRS[@]}"; do
        candidate="${d}/x86_64-windows/wminet_utils.dll"
        if [ -f "$candidate" ]; then wine_lib="$candidate"; break; fi
    done

    if [ -z "$wine_lib" ]; then
        echo "[wminet_utils proxy] ERROR: Wine wminet_utils.dll not found in any of:"
        printf '  %s\n' "${WINE_LIB_DIRS[@]}"
        echo "       Roon 2.65+ will crash without the proxy. Install Wine and rerun."
        return 1
    fi

    if [ ! -f "$script_dir/wminet_utils.dll" ]; then
        echo "[wminet_utils proxy] ERROR: bundled proxy DLL missing at $script_dir/wminet_utils.dll"
        echo "       Re-clone the repo or run 'make' to rebuild."
        return 1
    fi

    sys32="$PREFIX/drive_c/windows/system32"

    # Wait for any wineserver / wine child processes spawned by the Roon
    # installer to exit before touching system32. Without this, a lingering
    # process can load wminet_utils.dll mid-write and see a half-copied file.
    echo "[wminet_utils proxy] Waiting for wineserver to settle..."
    env WINEPREFIX=$PREFIX wineserver -w 2>/dev/null || true

    echo "[wminet_utils proxy] Installing prefix-local proxy DLLs to $sys32/ ..."
    # Copy via temp + atomic rename so a concurrent loader cannot observe
    # a partially-written DLL.
    if ! cp "$wine_lib" "$sys32/wminet_utils_wine.dll.tmp" \
       || ! mv "$sys32/wminet_utils_wine.dll.tmp" "$sys32/wminet_utils_wine.dll"; then
        rm -f "$sys32/wminet_utils_wine.dll.tmp"
        echo "[wminet_utils proxy] ERROR: failed to install $sys32/wminet_utils_wine.dll"
        return 1
    fi
    if ! cp "$script_dir/wminet_utils.dll" "$sys32/wminet_utils.dll.tmp" \
       || ! mv "$sys32/wminet_utils.dll.tmp" "$sys32/wminet_utils.dll"; then
        rm -f "$sys32/wminet_utils.dll.tmp"
        echo "[wminet_utils proxy] ERROR: failed to install $sys32/wminet_utils.dll"
        return 1
    fi

    echo "[wminet_utils proxy] Setting Wine registry override (native)..."
    if ! env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX wine reg add \
            "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides" \
            /v wminet_utils /t REG_SZ /d native /f >/dev/null 2>&1; then
        echo "[wminet_utils proxy] ERROR: failed to set DllOverrides registry key"
        return 1
    fi

    echo "[wminet_utils proxy] Done — wminet_utils=native set for prefix"
    echo "[wminet_utils proxy] Proxy DLL affects only this Wine prefix."
}

_install_wminet_proxy || {
    echo "ERROR: wminet_utils proxy install failed — aborting."
    echo "       Roon 2.65+ would crash on startup without it."
    exit 1
}

# Preconditions for start script. 
# Need a properly formatted path to the user's Roon.exe in their wine configuration
# Get the Windows OS formatted path to the user's Local AppData folder
WINE_LOCALAPPDATA="$( _wine '' cmd.exe /c echo %LocalAppData% )"

# Convert Windows OS formatted path to Linux formatted path from the user's wine configuration
UNIX_LOCALAPPDATA="$( _winepath -u $WINE_LOCALAPPDATA )"

# Windows line endings carry through winepath conversion. Remove it to get an error free path.
UNIX_LOCALAPPDATA=${UNIX_LOCALAPPDATA%$'\r'} # remove ^M

ROONEXE="/Roon/Application/Roon.exe"

# Auto-detect display scaling factor
AUTO_SCALE="1.0"
if command -v hyprctl >/dev/null 2>&1; then
    AUTO_SCALE=$(hyprctl monitors 2>/dev/null | grep "scale:" | head -1 | awk '{printf "%.1f", $2}')
fi
# awk emits empty on a missing scale: line, "0.0" on a malformed scan.
# Either case is a fallback signal — clamp to 1.0.
case "$AUTO_SCALE" in
    ""|"0.0") AUTO_SCALE="1.0" ;;
esac

# Preconditions for start script met.
# create start script
cat << _EOF_ > ./start_my_roon_instance.sh
#!/usr/bin/env bash

# UI scale factor — auto-detected from display settings.
# Change this value if the auto-detected scale is incorrect.
# 1.0 is default, on UHD screens typically 1.5–2.0.

SCALEFACTOR=${AUTO_SCALE}

PREFIX="$PREFIX"
env WINEPREFIX="$PREFIX" \\
    WINEFSYNC=1 \\
    WINEDEBUG=-all \\
    WINEFSYNC_SPINCOUNT=2000 \\
    WINEDLLOVERRIDES="windows.media.mediacontrol=" \\
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \\
    __GL_SHADER_DISK_CACHE=1 \\
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1 \\
    wine "${UNIX_LOCALAPPDATA}${ROONEXE}" -scalefactor=\$SCALEFACTOR
_EOF_

chmod +x ./start_my_roon_instance.sh
cp ./start_my_roon_instance.sh ~

# Set Roon to dark theme by default
ROON_SETTINGS="${UNIX_LOCALAPPDATA}/Roon/Settings"
mkdir -p "$ROON_SETTINGS"
echo "Dark" > "$ROON_SETTINGS/theme"

# create XDG stuff
cat << _EOF2_ > ${HOME}/.local/share/applications/roon-on-wine.desktop
[Desktop Entry]
Name=Roon
Exec=${HOME}/start_my_roon_instance.sh
Terminal=false
Type=Application
StartupNotify=true
Icon=0369_Roon.0
StartupWMClass=roon.exe
_EOF2_

cp ./icons/16x16/roon-on-wine.png ${HOME}/.local/share/icons/hicolor/16x16/apps/0369_Roon.0.png
cp ./icons/32x32/roon-on-wine.png ${HOME}/.local/share/icons/hicolor/32x32/apps/0369_Roon.0.png
cp ./icons/48x48/roon-on-wine.png ${HOME}/.local/share/icons/hicolor/48x48/apps/0369_Roon.0.png
cp ./icons/256x256/roon-on-wine.png ${HOME}/.local/share/icons/hicolor/256x256/apps/0369_Roon.0.png

# refresh XDG stuff
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache

echo
echo "DONE!"
echo

exit 0
