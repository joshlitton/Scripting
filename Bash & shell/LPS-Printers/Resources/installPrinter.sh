#!/bin/sh

#Installers
INST1="/tmp/Ricoh_PS_Printers_Vol4_EXP_LIO_Driver.pkg"
INST2="/tmp/Ricoh_PS_Printers_Vol2_EXP_LIO_Driver.pkg"

installer -pkg "$INST1" -target /
installer -pkg "$INST2" -target /

# Name
PRINTER="Cluster3-Ricoh-MP4001_x64"
# SMB, IPP or LPD address
URIPATH="LPD://10.148.63.253"
# Driver Path
PRINTDRV="/Library/Printers/PPDs/Contents/Resources/RICOH Aficio MP 4001"
# Description
DISPLAYNAME="Cluster3-Ricoh-MP4001_x64"
# Location of printer
LOCATION="Cluster 3"

# replace -P "$PRINTDRV" with -m "drv:///sample.drv/genericps.ppd"
lpadmin -p "$PRINTER" -E -v "$URIPATH" -P "$PRINTDRV" -D "$DISPLAYNAME" -L "$LOCATION" \
-o printer-is-shared=false \

sleep 1.5

# Name
PRINTER="Library-Ricoh-MP4054_x64"
# SMB, IPP or LPD address
URIPATH="LPD://10.148.63.246"
# Driver Path
PRINTDRV="/Library/Printers/PPDs/Contents/Resources/RICOH MP 4054"
# Description
DISPLAYNAME="Library-Ricoh-MP4054_x64"
# Location of printer
LOCATION="Library"

# replace -P "$PRINTDRV" with -m "drv:///sample.drv/genericps.ppd"
lpadmin -p "$PRINTER" -E -v "$URIPATH" -P "$PRINTDRV" -D "$DISPLAYNAME" -L "$LOCATION" \
-o printer-is-shared=false \

sleep 1.5

# Name
PRINTER="Admin-Ricoh-MPC4504_x64"
# SMB, IPP or LPD address
URIPATH="LPD://10.148.63.247"
# Driver Path
PRINTDRV="/Library/Printers/PPDs/Contents/Resources/RICOH MP C4504"
# Description
DISPLAYNAME="Admin-Ricoh-MPC4504_x64"
# Location of printer
LOCATION="Admin"

# replace -P "$PRINTDRV" with -m "drv:///sample.drv/genericps.ppd"
lpadmin -p "$PRINTER" -E -v "$URIPATH" -P "$PRINTDRV" -D "$DISPLAYNAME" -L "$LOCATION" \
-o printer-is-shared=false \

sleep 0.5

exit 0
