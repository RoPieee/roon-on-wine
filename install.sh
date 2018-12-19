#!/bin/bash

WIN_ROON_DIR=my_roon_instance
ROON_DOWNLOAD=http://download.roonlabs.com/builds/RoonInstaller.exe

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




# check necessary stuff
_check_for_executable wine
_check_for_executable winecfg
_check_for_executable winetricks
_check_for_executable wget

# configure Wine
rm -rf $HOME/$WIN_ROON_DIR
env WINEPREFIX=$PREFIX WINEARCH=win32 wine wineboot
#env WINEPREFIX=$HOME/$WIN_ROON_DIR winecfg

# this is required to make sure the system.reg is settled
sleep 5

# set Windows version to Windows 7
sed -i 's/"ProductName"=.*/"ProductName"="Microsoft Windows 7"/' $HOME/$WIN_ROON_DIR/system.reg
sed -i 's/"ProductType"=.*/"ProductType"="WinNT"/' $HOME/$WIN_ROON_DIR/system.reg

# install .Net 4.5
env WINEPREFIX=$PREFIX winetricks -q dotnet45

sleep 2

sed -i 's/"CurrentVersion"=.*/"CurrentVersion"="6.1"/' $HOME/$WIN_ROON_DIR/system.reg
sed -i 's/"CSDVersion"=.*/"CSDVersion"="Service Pack 1"/' $HOME/$WIN_ROON_DIR/system.reg
sed -i 's/"CurrentBuildNumber"=.*/"CurrentBuildNumber"="7601"/' $HOME/$WIN_ROON_DIR/system.reg

# download Roon if necessary
test -f $( basename $ROON_DOWNLOAD ) || wget $ROON_DOWNLOAD

# install Roon
env WINEPREFIX=$PREFIX wine $( basename $ROON_DOWNLOAD )


# create start script
cat << _EOF_ > ./start_my_roon_instance.sh
#!/bin/bash

PREFIX=$PREFIX
env WINEPREFIX=$PREFIX wine $PREFIX/'drive_c/users/$USER/Local Settings/Application Data/Roon/Application/Roon.exe'
_EOF_

chmod +x ./start_my_roon_instance.sh

exit 0
