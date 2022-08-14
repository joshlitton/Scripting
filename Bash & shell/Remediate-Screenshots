#!/bin/bash
 
# Enable debug
set -xv
 
# Remove Jamf Protect extension attribute 
rm /Library/Application\ Support/JamfProtect/groups/protect-Screenshot
 
# Check for existing depnotify log and delete it if found
if [ -f /var/tmp/depnotify.log ]; then
	rm /var/tmp/depnotify.log
fi

# Check if the DEP Notify app is installed, if not notify the user 
if [ -f "/Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify" ]; then 
		/Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify -fullScreen & 
	else
		echo "DEP Notify Not Present... Exiting" 
		exit 1; 
fi
 
# Icon for the notification dialog
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns" >> /var/tmp/depnotify.log
 
# Title for the notification dialog
echo "Command: MainTitle: Jamf Protect Remediation" >> /var/tmp/depnotify.log
 
# Main Body Text
echo "Command: MainText: Jamf Protect has detected malicious activity on this computer.\n\nYou may resume using your Mac once the malicious incident has been isolated.\n\n If this screen remains for longer than five minutes, please call the IT Department using the number on the back of your ID badge." >> /var/tmp/depnotify.log
 
# Status Message 
echo "Status: Remediation in progress..." >> /var/tmp/depnotify.log 
echo "Command: DeterminateManualStep" >> /var/tmp/depnotify.log
sleep 4
 
# Save the value of the existing IFS
oldIFS=$IFS
# Set the IFS to newline only
IFS=$'\n'
 
# Create an array of all the existing screenshots
screenshots+=($(mdfind kMDItemIsScreenCapture:1))
# Output the number of elements in the array
echo "Command: DeterminateManual: ${#screenshots[@]}" >> /var/tmp/depnotify.log
# Loop through the array, delete and notify user of each screenshot that is removed
for screenshot in ${screenshots[@]};do
 echo "Deleting $screenshot"
 echo "Status: Deleting $screenshot" >> /var/tmp/depnotify.log
 echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log 
 rm "$screenshot"
 sleep 2
done
 
# Return the IFS to it's previous value
IFS=$oldIFS
 
echo "Status: " >> /var/tmp/depnotify.log
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log
 
# Completed Title notification
echo "Command: MainTitle: Remediation Complete" >> /var/tmp/depnotify.log

# Completed Icon 
echo "Command: Image: /Applications/JamfProtect.app/Contents/Resources/AppIcon.icns" >> /var/tmp/depnotify.log

# Completed Text Body 
echo "Command: MainText: The malicious element was isolated. Thank you for your patience.\n\nAs a reminder, your security is of the utmost importance. If you receive any unusual emails or phone calls asking for your username, password, or any other requests, please call the IT Department using the number on the back of your ID badge." >> /var/tmp/depnotify.log
 
# Pause for 3 seconds
sleep 3
 
# Quit DEPNotify
echo "Command: Quit: Remediation Complete" >> /var/tmp/depnotify.log
 
# Remove the DEPNotify log file
rm /var/tmp/depnotify.log
 
# Stop the DEPNotify process and remove the DEPNotify app
pkill DEPNotify
rm -R /Applications/Utilities/DEPNotify.app
 
exit 0