# Running Roon on Linux with Wine

This script makes it possible to run Roon on Wine. It creates a separate Wine instance in a folder; this is required for Roon.

Right now the script is very rudimentary: more stuff is coming soon. Keep in mind that you need the following programs to be installed on your Linux system:

* wine
* winetricks
* winecfg
* wget

## Wine version

With respect to which version of Wine... this is a bit 'hit-and-miss'. 

### Wine versions tested
Ubuntu 20.04 (Focal Fossa) / Linux Mint 20x requires at least 'winehq-stable' (wine version 7.0+) or 'winehq-staging' (wine version 7.22+)

# Install 
To install Roon just clone or download this repository and run <code>./install.sh</code>

Be patient, as installing the necessary components for Wine can take some time. Don't be scared of the messages that flood the console: drink a coffee and wait...

The installation is basically unattended. When the Roon installer starts you will need to click 'Install'.

When finished you can start Roon with <code>./start_my_roon_instance.sh</code>

## "Resolution too small" error
If you see a "Resolution too small" error when launching Roon, you will need to need to edit the <code>install.sh</code> script and reinstall.
To do that:
* On line 9, change the variable <code>SET_SCALEFACTOR=0</code> to <code>SET_SCALEFACTOR=1</code>.
* Save the script and re-run it with <code>./install.sh</code>


# Supported distro's
This scripts has been reported to work on:

* ArchLinux
* KDE Neon
* openSUSE
* Fedora

IF your distro is missing please leave a note!
