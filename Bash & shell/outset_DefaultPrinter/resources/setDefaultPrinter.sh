#!/bin/sh

#Name of Printer
PRINTER="LIB-FXApeosPort-IVC5575_x64"
PRINTPREFS="~/Library/Preferences/org.cups.PrintingPrefs.plist"

defaults write "$PRINTPREFS" UseLastPrinter -bool FALSE
sleep 0.5
lpoptions -d "$PRINTER"

exit 0
