#!/bin/bash

# Our Binary: 
dockutil="/usr/local/bin/dockutil"
dockItems=("$4")                        # Application full pathways separated by a ";" (ie. /Applications/Microsoft Edge.app;/Applications/Microsoft Word.app)
selfServiceFlag="${5:-"true"}"          # Add Self Service app to Dock? (true/false) Default=true and will set to beginning of dock, after finder. 
sysPrefsFlag="${6:-"true"}"             # Add System Settings to Dock? (true/false) Default=true and will set position to end of dock

# Clear the dock
$dockutil --remove all --allhomes '/System/Library/User Template/Engligh.lproj' --no-restart

# We are expecting ; as the separator
OLDIFS=$IFS
IFS=";"

for item in $dockItems; do
	$dockutil --add "$item" --allhomes '/System/Library/User Template/Engligh.lproj' --no-restart
done

if $selfServiceFlag = "true"; then
	$dockutil --add "/Applications/Self Service.app" --position 1 --allhomes '/System/Library/User Template/Engligh.lproj' --no-restart
fi

if $sysPrefsFlag = "true"; then
	version=$(sw_vers | grep ProductVersion | awk '{print $2}')
    version=${version:0:2}
    echo "Major OS Version is: $version"
    if (($(echo $version)<13)); then
    	echo "$version is less than 13"
    	$dockutil --add "/System/Applications/System Preferences.app" --position end --allhomes '/System/Library/User Template/Engligh.lproj' --no-restart
    else 
    	echo "$version is 13 or greater"
        $dockutil --add "/System/Applications/System Settings.app" --position end --allhomes '/System/Library/User Template/Engligh.lproj' --no-restart
    fi
fi

killall Dock