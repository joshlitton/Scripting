#!/bin/sh

PROFS="/Library/Profiles/*.mobileconfig"

for p in $PROFS
do
  echo "Processing $p for $USER"
  /usr/bin/profiles -IvF "$p"
  echo "Completed!"
done

exit 0
