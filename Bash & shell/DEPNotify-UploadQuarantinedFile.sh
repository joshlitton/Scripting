#!/bin/bash
 
# enable debug
set -xv
 
# Remove DEP Notify log if present 
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
 
# Update the DEPNotify progress bar
echo "Command: DeterminateManual: 5" >> /var/tmp/depnotify.log
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log

# Update DEPNotify Status Message
echo "Status: Remediation in progress..." >> /var/tmp/depnotify.log
sleep 3
 
# Update DEPNotify Status Message
echo "Status: Compressing forensic artifacts..." >> /var/tmp/depnotify.log
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log
sleep 3

# Capture the date & time
dateStamp=$(date +%Y_%m_%d-%H_%M_%S)
 
# Zip the Malware
cd /Library/Application\ Support/JamfProtect/Quarantine/*; zip -r -X "../Malware-$dateStamp.zip" *

# Update DEPNotify Status Message
echo "Status: Moving forensic artifacts..." >> /var/tmp/depnotify.log
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log
sleep 3

# Move Malware to a new location, Default is /Users/Shared
cd /Library/Application\ Support/JamfProtect/Quarantine/; mv "Malware-$dateStamp.zip" /Users/Shared/
 
# Remove the Quarantined Malware
rm -R /Library/Application\ Support/JamfProtect/Quarantine/*

# Update DEPNotify Status Message
echo "Status: Uploading forensic artifacts..." >> /var/tmp/depnotify.log
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log
sleep 3

# File to upload is the first argument
file="/Users/Shared/Malware-$dateStamp.zip"
filePath="$file"
 
# Parse file name
file1=`echo $file | awk -F '/' '{print$NF}'`
macSerial=`system_profiler SPHardwareDataType | awk '/Serial/{print$NF}'`
timeStamp=`date +%s`
uploadName="$macSerial-$timeStamp-$file1"
 
# Specify destination bucket
bucket=edu-demo-20210326
resource="/${bucket}/${uploadName}"
 
# Obtain content type
contentType=`file -b --mime-type $file`
dateValue=`date -R`
 
# Calculate string to sign
stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
 
# S3 Key and S3 Secret
s3Key="$4"
s3Secret="$5"
 
# Generate signature
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
 
# Upload file to bucket
curl -X PUT -T "$filePath" \
-H "Host: ${bucket}.s3.amazonaws.com" \
-H "Date: ${dateValue}" \
-H "Content-Type: ${contentType}" \
-H "Authorization: AWS ${s3Key}:${signature}" \
https://${bucket}.s3.amazonaws.com/${uploadName}

# Clear DEPNotify Status Message
echo "Command: DeterminateManualStep: 1" >> /var/tmp/depnotify.log
echo "Status: " >> /var/tmp/depnotify.log

# DEPNotify app Completed Title 
echo "Command: MainTitle: Remediation Complete" >> /var/tmp/depnotify.log

# DEPNotify app Completed Icon 
echo "Command: Image: /Applications/JamfProtect.app/Contents/Resources/AppIcon.icns" >> /var/tmp/depnotify.log 

# DEPNotify app Completed Text Body
echo "Command: MainText: The malicious element was isolated. Thank you for your patience.\n\nAs a reminder, your security is of the utmost importance. If you receive any unusual emails or phone calls asking for your username, password, or any other requests, please call the IT Department using the number on the back of your ID badge." >> /var/tmp/depnotify.log
 sleep 4
 
# Quit the DEPNotify app
echo "Command: Quit" >> /var/tmp/depnotify.log

# Remove the DEPNotify log file
rm /var/tmp/depnotify.log

# Remove Forensic Artifact from the computer
rm -rf /Users/Shared/Malware*.zip

# Remove Jamf Protect Extension Attribute 
rm /Library/Application\ Support/JamfProtect/groups/protect-QuarantinedFile

# Quit DEPNotify app if the quit command failed
pkill DEPNotify

# Remove DEPNotify.app
rm -R /Applications/Utilities/DEPNotify.app
 
exit 0