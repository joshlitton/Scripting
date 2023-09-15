#!/bin/bash

repo="https://github.com/CITWA/appleLoops/archive/master.zip"
dest="/Library/Application Support/kcc"
loops="$dest/appleloops-master/appleLoops"
# Download the Zip file of the GitHub Repository
/usr/bin/curl -o /tmp/appleLoops.zip -LO "$repo"

# Extract Zip
/usr/bin/unzip -qo /tmp/appleLoops.zip -d "$dest"

sleep 1

if [[ -f $loops ]]; then
	exit 0
else
	exit 1
fi

# Run the tool to download and install Apple Loops
#Updated to call using python to fix Appleloops3 November 2020 update

#python /tmp/appleLoops-master/appleLoops --deployment -a garageband -c http://10.42.11.1:51186 -q -m -o -u

exit 0
