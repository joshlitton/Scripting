#!/bin/zsh
# SCRIPT INFORMATION
VERSION=1.1
AUTHOR="Josh Litton - Catalytic IT"

# Variables
############################
scriptFolder="/Library/Management/scripts/"
scriptLocation="${scriptFolder}notify.sh"
log="/private/var/log/preDeploy.log"
prefFile="/Library/Preferences/com.jamf.connect.login"
NOTIFY_LOG="/var/tmp/depnotify.log"
extAttFolder="/Library/Management/xattr/"
extAttFile="${extAttFolder}com.notify.provision.done"
# Utility Shorthands
############################
jamfBin="/usr/local/bin/jamf"
authchanger="/usr/local/bin/authchanger"

# Check and create folders if required. 
if [[ ! -d "$extAttFolder" ]]; then
	echo "${extAttFolder} does not exist. Creating."
	mkdir -p "$extAttFolder"
fi
if [[ ! -d "$scriptFolder" ]]; then
	echo "${scriptFolder} does not exist. Creating."
	mkdir -p "$scriptFolder"
fi

echo "Starting Script" >> "$log" 
if [[ ${4} == "" ]]; then
	echo "No policies detected to be run. Exiting..." >> "$log"
    exit 1
fi

# Install Jamf Connect if not installed
if [[ -d "/Applications/Jamf Connect.app/" ]]; then
  echo "Downloading JamfConnect" >> "$log" 
  /usr/local/Installomator/Installomator.sh jamfconnect NOTIFY=silent BLOCKING_PROCESS_ACTION=kill
fi

sleep 1
# Remove the notify log if it exists
while pgrep -q -x "Setup Assistant"; do
    echo "Setup Assistant is still running; pausing for 2 seconds" >> "$log"
    sleep 2
done

# Delete any existing logs if we find one. 
if [[ "$NOTIFY_LOG" ]]; then
	rm -Rf "$NOTIFY_LOG"
fi

echo "Copying deploy script to ${scriptLocation}" > "${log}"
tee "${scriptLocation}" << EOS
#!/bin/zsh

# Disable for prod
# Allows to run this script on a machine to test how DEPNotify will present
#/Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify &

# Heredoc Variables
############################
policiesArray=(${4})
testingMode=${6:-"true"}
cleanUpTrigger=${7:-"predeploy-cleanup"}

# NOTIFY WINDOW SETUP
########################

echo "STARTING RUN" >> $NOTIFY_LOG

echo "Time to caffeniate..." >> $NOTIFY_LOG
caffeinate -d -i -m -s -u &

# Total setups to go through
echo "Command: DeterminateOff:" >> $NOTIFY_LOG

# Set our logo
echo "Command: MainTitle: Deploying Apps and Settings" >> $NOTIFY_LOG

echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-13-retina-usbc-space-gray.icns" >> $NOTIFY_LOG

echo "Command: MainText: Your new Mac has successfully enrolled to the Jamf Pro server. Please wait while we install the required applications for your organisation." >> $NOTIFY_LOG

echo "Status: Preparing Mac..." >> "$NOTIFY_LOG"
sleep 10

echo "Command: DeterminateOffReset:" >> "$NOTIFY_LOG"
echo "Command: Determinate: \$(( \${#policiesArray[@]} + 1 ))" >> "$NOTIFY_LOG"

# POLICY LOOP
for POLICY in \${policiesArray[@]}; do
	# Write name to message
	echo "Status: \$(echo "\$POLICY" | cut -d ',' -f1)" >> "$NOTIFY_LOG"
    trigger="\$(echo "\$POLICY" | cut -d ',' -f2)"
	if [ "\$testingMode" = true ]; then
		sleep 10
	elif [ "\$testingMode" = false ]; then
		"$jamfBin" policy -event "\${trigger}"
	fi
done

echo "Command: MainText: Successfully deployed the standard operating environment - performing clean up, the Mac will restart shortly." >> $NOTIFY_LOG

echo "Status: Wrapping up..." >> $NOTIFY_LOG

if [[ "\${testingMode}" = true ]]; then 
	sleep 10
    mkdir -p "${extAttFolder}" && touch "${extAttFile}"
    "$jamfBin" policy -event \${cleanUpTrigger}
elif [[ "\${testingMode}" = false ]]; then
	"$jamfBin" policy -event \${cleanUpTrigger}
    mkdir -p "${extAttFolder}" && touch "${extAttFile}"
fi
sleep 3
echo "Command: Quit:" >> $NOTIFY_LOG

#shutdown -r now
/usr/bin/killall -HUP loginwindow

exit 0

EOS

# Script Permissions
chown root:wheel "${scriptLocation}"
chmod 777 "${scriptLocation}"
chmod +x "${scriptLocation}"

# Set permissions for NoLoAD ScriptPath
defaults write "${prefFile}" ScriptPath "${scriptLocation}"
echo "ScriptPath set to:" >> "${log}"
defaults read "${prefFile}" ScriptPath >> "${log}"
sleep 1

# Hand-off to JC for Notify
/usr/local/bin/authchanger -reset -prelogin JamfConnectLogin:Notify
/usr/local/bin/authchanger -prelogin JamfConnectLogin:RunScript,privileged

echo "Reloading login window with auth.db settings:" >> "${log}"
${authchanger} -print >> "${log}"
sleep 1

# Restart, not fully necessary
#shutdown -r now
# Restart the login window to kick Notify
/usr/bin/killall -HUP loginwindow