#!/bin/bash

WIN_ROON_DIR=my_roon_instance
ROON_DOWNLOAD=http://download.roonlabs.com/builds/RoonServerInstaller.exe

PREFIX="$HOME/$WIN_ROON_DIR"



# configure Wine
rm -rf $HOME/$WIN_ROON_DIR
env WINEPREFIX=$PREFIX WINEARCH=win32 wine wineboot
#env WINEPREFIX=$HOME/$WIN_ROON_DIR winecfg

# this is required to make sure the system.reg is settled
sleep 5

# set Windows version to Windows 7
sed -i 's/"ProductName"=.*/"ProductName"="Windows 7"/' $HOME/$WIN_ROON_DIR/system.reg

# install .Net 4.5
env WINEPREFIX=$PREFIX winetricks -q dotnet45

# download Roon
wget $ROON_DOWNLOAD

# install Roon
env WINEPREFIX=$PREFIX wine $( basename $ROON_DOWNLOAD )


exit




env WINEPREFIX=$HOME/$WIN_ROON_DIR wine $WINEPREFIX/drive_c/users/$USER/Local \Settings/Application\ Data/Roon/Application/Roon.exe

exit 0
