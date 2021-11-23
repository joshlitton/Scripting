#!/bin/sh

# Name
PRINTER="Admin_Staff_KonicaMinolta_C458_x64"
# SMB, IPP or LPD address
URIPATH="smb://E5296S01SV006.green.schools.internal/Admin_Staff_KonicaMinolta_C458_x64"
# Driver Path
PRINTDRV="/Library/Printers/PPDs/Contents/Resources/KONICAMINOLTAC458.PPD"
# Description
DISPLAYNAME="Admin_Staff_KonicaMinolta_C458_x64"
# Location of printer
LOCATION="Admin Copy Room"

# replace -P "$PRINTDRV" with -m "drv:///sample.drv/genericps.ppd"
lpadmin -p "$PRINTER" -E -v "$URIPATH" -P "$PRINTDRV" -D "$DISPLAYNAME" -L "$LOCATION" \
-o printer-is-shared=false \
-o auth-info-required=negotiate

exit 0
