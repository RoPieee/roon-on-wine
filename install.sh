#!/bin/bash

#set -x
WIN_ROON_DIR=my_roon_instance
ROON_DOWNLOAD=http://download.roonlabs.com/builds/RoonInstaller64.exe
WINETRICKS_DOWNLOAD=https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
WINE_PLATFORM="win64"
test "$WINE_PLATFORM" = "win32" && ROON_DOWNLOAD=http://download.roonlabs.com/builds/RoonInstaller.exe
SET_SCALEFACTOR=1
VERBOSE=1

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
   echo "[${WINE_PLATFORM}|${PREFIX}] $comment ..."
   if [ $VERBOSE -eq 1 ]
   then
      #env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX wine "$@"
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX WINEDLLOVERRIDES=winemenubuilder.exe=d wine "$@"
   else
      #env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX wine "$@" >/dev/null 2>&1
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX WINEDLLOVERRIDES=winemenubuilder.exe=d wine "$@" >/dev/null 2>&1
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
_winetricks "Installing .NET 4.5.2"  -q --force dotnet452
#_winetricks "Installing .NET 4.6.2" -q dotnet462
#_winetricks "Installing .NET 4.7.2" -q dotnet472
#_winetricks "Installing .NET 4.8" -q dotnet48

# setting some environment stuff
_winetricks "Setting Windows version to 10" -q win10
_winetricks "Setting DDR to OpenGL"        -q ddr=opengl
_winetricks "Disabling crash dialog"       -q nocrashdialog

rm -f ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe
# wget 'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
wget 'https://download.visualstudio.microsoft.com/download/pr/1f5af042-d0e4-4002-9c59-9ba66bcf15f6/089f837de42708daacaae7c04b7494db/ndp472-kb4054530-x86-x64-allos-enu.exe' -O ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe
_wine "Installing .NET..." ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe /q

sleep 2

# download Roon
rm -rf $ROON_DOWNLOAD
test -f $( basename $ROON_DOWNLOAD ) || wget $ROON_DOWNLOAD

# install Roon
_wine "Installing Roon" $( basename $ROON_DOWNLOAD  )

# create start script
cat << _EOF_ > ./start_my_roon_instance.sh
#!/bin/bash

SET_SCALEFACTOR=$SET_SCALEFACTOR

PREFIX=$PREFIX
if [ $SET_SCALEFACTOR -eq 1 ]
then
   env WINEPREFIX=$PREFIX wine $PREFIX/drive_c/users/$USER/AppData/Local/Roon/Application/Roon.exe -scalefactor=2
else
   env WINEPREFIX=$PREFIX wine $PREFIX/drive_c/users/$USER/AppData/Local/Roon/Application/Roon.exe
fi
_EOF_

chmod +x ./start_my_roon_instance.sh
cp ./start_my_roon_instance.sh ~

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

exit 0
