#!/bin/sh

PRINTERNAME="FollowMePrint"
PRINTERCHECK=$(lpstat -p | awk '{print $2}' | grep -c "$PRINTERNAME")
# Search for existing printer

if [[ $(lpstat -p | awk '{print $2}' | grep -c "$PRINTERNAME") -gt 0 ]]; then
  echo "Found printer, uninstalling"
  lpadmin -x "$PRINTERNAME"
else
  echo "No printer installed"
fi

exit 0
