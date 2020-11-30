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
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX wine "$@"
   else
      env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX wine "$@" >/dev/null 2>&1
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
_winetricks "Installing .NET 4.0"    -q --force dotnet40
#_winetricks "Installing .NET 4.5"    -q --force dotnet45
#_winetricks "Installing .NET 4.5.2"  -q --force dotnet452
#_winetricks "Installing .NET 4.6.2" -q dotnet462
#_winetricks "Installing .NET 4.7.2" -q dotnet472
#_winetricks "Installing .NET 4.8" -q dotnet48

# setting some environment stuff
_winetricks "Setting Windows version to 7" -q win7
_winetricks "Setting DDR to OpenGL"        -q ddr=opengl
#_winetricks "Installing WMI"               -q wmi

rm -f ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe
wget 'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
_wine "Installing .NET..." ./NDP472-KB4054530-x86-x64-AllOS-ENU.exe /q

#if [ "$WINE_PLATFORM" = "win32" ]
#then
#   _winetricks "Installing WMI" -q wmi
#fi

sleep 2

# download Roon if necessary
test -f $( basename $ROON_DOWNLOAD ) || wget $ROON_DOWNLOAD

# install Roon
#env WINEARCH=$WINE_PLATFORM WINEPREFIX=$PREFIX wine $( basename $ROON_DOWNLOAD )
_wine "Installing Roon" $( basename $ROON_DOWNLOAD  )


# create start script
cat << _EOF_ > ./start_my_roon_instance.sh
#!/bin/bash

SET_SCALEFACTOR=$SET_SCALEFACTOR

PREFIX=$PREFIX
if [ $SET_SCALEFACTOR -eq 1 ]
then
   env WINEPREFIX=$PREFIX wine $PREFIX/'drive_c/users/$USER/Local Settings/Application Data/Roon/Application/Roon.exe' -scalefactor=2
else
   env WINEPREFIX=$PREFIX wine $PREFIX/'drive_c/users/$USER/Local Settings/Application Data/Roon/Application/Roon.exe'
fi
_EOF_

chmod +x ./start_my_roon_instance.sh
cp ./start_my_roon_instance.sh ~

exit 0
