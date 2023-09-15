#!/bin/sh

#Printer SMB Name
PNT="KyoceraP2040DW_HASSOffice_x64"
#Print Server Address
SVR="E4159S01SV006.green.schools.internal"
#School Name
SCH="Warnbro Community High School"
#Driver File Name
DRV="Kyocera ECOSYS P2040dw.PPD"

#Run Command with variables
lpadmin -p "${PNT}" -E -L "${SCH}" -v "SMB://${SVR}/${PNT}" -P "/Library/Printers/PPDs/Contents/Resources/${DRV}" -o printer-is-shared=false -o auth-info-required=negotiate