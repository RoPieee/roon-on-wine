# Running Roon on Linux with Wine

This script makes it possible to run Roon on Wine.
It creates a separate Wine instance in a folder; this is required for Roon.

Right now the script is very rudimentary: more stuff coming soon. Keep in mind that you need the following programs to be installed on your Linux system:

* wine
* winetricks
* winecfg
* wget

With respect to the version of Wine... this is a 'hit-and-miss'. For now it seems you need a (64-bit) Wine version below or equal to 5.11. 
In general this means that if you choose to install what's known as 'wine stable' you're on the safe side.

To install Roon just clone or download this reposity and run <code>./install.sh</code>

Be patient, installing the necessary componens for Wine can take a time. Don't be scared of the messages that flood the console. Take a coffee and wait...

The installation is basically unattended. When the Roon installer starts you need to click 'Continue'.

When finished you can start Roon with <code>./start_my_roon_instance.sh</code>

# Supported distro's
This scripts has been reported to work on:

* ArchLinux
* KDE Neon
* openSUSE
* Fedora

IF your distro is missing please leave a note!
