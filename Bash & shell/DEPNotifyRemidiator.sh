#!/bin/bash
 
# enable debug
set -xv
if [ -f /var/tmp/depnotify.log ]; then
	rm /var/tmp/depnotify.log
fi
 
# DEP Notify for Jamf Protect 
if [ -f "/Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify" ]; then 
		/Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify &
	else
		echo "DEP Notify Not Present... Exiting" 
		exit 1; 
fi
 
# Update DEPNotify Icon
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns" >> /var/tmp/depnotify.log

# Update DEPNotify Title 
echo "Command: MainTitle: Jamf Protect Remediation" >> /var/tmp/depnotify.log

# Update DEPNotify Main Body Text
echo "Command: MainText: Jamf Protect has detected malicious activity on this computer.\n\nYou may resume using your Mac once the malicious incident has been isolated.\n\n If this screen remains for longer than five minutes, please call the IT Department using the number on the back of your ID badge." >> /var/tmp/depnotify.log
 
# Update DEPNotify Status Message 
echo "Status: Remediation in progress..." >> /var/tmp/depnotify.log
sleep 6
echo "Command: DeterminateManual: 2" >> /var/tmp/depnotify.log 

# Update DEPNotify Status Message 
echo "Status: Removing Login and Logout hooks..." >> /var/tmp/depnotify.log
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log
sleep 6
 
# Remove the login and logout hooks
defaults delete /var/root/Library/Preferences/com.apple.loginwindow LoginHook
defaults delete /var/root/Library/Preferences/com.apple.loginwindow LogoutHook
 
# Clear the DEPNotify Status Message 
echo "Status: " >> /var/tmp/depnotify.log
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log

# Update DEPNotify Completed Title 
echo "Command: MainTitle: Remediation Complete" >> /var/tmp/depnotify.log

# Update DEPNotify Completed Icon 
echo "Command: Image: /Applications/JamfProtect.app/Contents/Resources/AppIcon.icns" >> /var/tmp/depnotify.log 

# Update DEPNotify Completed Text Body 
echo "Command: MainText: The malicious element was isolated. Thank you for your patience.\n\nAs a reminder, your security is of the utmost importance. If you receive any unusual emails or phone calls asking for your username, password, or any other requests, please call the IT Department using the number on the back of your ID badge." >> /var/tmp/depnotify.log
sleep 6
 
# Quit the DEPNotify app
echo "Command: Quit: Remediation Complete" >> /var/tmp/depnotify.log

# Remove Jamf Protect Extension Attribute
rm /Library/Application\ Support/JamfProtect/groups/protect-LoginHook

# Remove the DEPNotify log file
rm /var/tmp/depnotify.log
 
# Stop the DEPNotify process and remove the DEPNotify app
pkill DEPNotify
rm -R /Applications/Utilities/DEPNotify.app
 
exit 0