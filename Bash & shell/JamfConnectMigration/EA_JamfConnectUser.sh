#!/bin/sh

#Get current signed in user
 currentUser=$(ls -l /dev/console | awk '/ / { print $3 }')

#com.jamf.connect.state.plist location
 jamfConnectStateLocation=/Users/$currentUser/Library/Preferences/com.jamf.connect.state.plist
 
 UserEmail=$(/usr/libexec/PlistBuddy -c "Print :DisplayName" $jamfConnectStateLocation || echo "Does not exist")
echo "UserEmail"
echo "<result>$UserEmail</result>"