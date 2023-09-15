#!/bin/sh

# Name
PRINTER="FollowMePrint"
# SMB, IPP or LPD address
URIPATH="smb://E5764S01SV011.green.schools.internal/FollowMePrint"
# Driver Path
PRINTDRV="/Library/Printers/PPDs/Contents/Resources/FX ApeosPort-VII C7773 PS.gz"
# Description
DISPLAYNAME="Follow Me Printer"
# Location of printer
LOCATION="PapercutMF Virtual Queue"

DRVINST="/tmp/Fuji Xerox PS Plug-in Installer.pkg"

# Comment out if not deploying printer drivers with printer installed
installer -pkg "$DRVINST" -target /

# Uncomment the following two lines to use generic apple suppliced PCL driver. PCL can be swapped out for PS driver too.
#/usr/libexec/cups/daemon/cups-driverd cat drv:///sample.drv/generpcl.ppd >> /tmp/genericpcl.ppd
#lpadmin -p "$PRINTER" -E -v "$URIPATH" -P "/tmp/genericpcl.ppd" -D "$DISPLAYNAME" -L "$LOCATION" \
lpadmin -p "$PRINTER" -E -v "$URIPATH" -P "$PRINTDRV" -D "$DISPLAYNAME" -L "$LOCATION" \
-o printer-is-shared=false \
-o auth-info-required=negotiate

function cleanExit {
  rm -f "$DRVINST"
}

trap cleanExit 1 2 3 4 5 6
