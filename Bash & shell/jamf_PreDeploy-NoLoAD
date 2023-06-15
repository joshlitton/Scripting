#!/bin/zsh

#Variables
authchanger="/usr/local/bin/authchanger"
scriptLocation="/private/var/tmp/notify.sh"
log="/private/var/log/preDeploy.log"
prefFile="/Library/Preferences/menu.nomad.login.ad.plist"

echo "Copying deploy script to ${scriptLocation}" > "${log}"
tee "${scriptLocation}" << \EOS
#!/bin/zsh
NOTIFY_LOG="/var/tmp/depnotify.log"
GIVEN_NAME="Archie"

echo "STARTING RUN" >> $NOTIFY_LOG # Define the number of increments for the progress bar
echo "Command: Determinate: 6" >> $NOTIFY_LOG

#1 - Introduction window with username and animation
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-13-retina-usbc-space-gray.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Starting PreDeployment" >> $NOTIFY_LOG
echo "Command: MainText: Your Mac is now enrolled and will be automatically configured for you." >> $NOTIFY_LOG
echo "Status: Preparing your new Mac..." >> $NOTIFY_LOG
sleep 10
 
#2 - Setting up single sign-on passwords for local account
echo "Command: Image: /Applications/Utilities/Keychain Access.app/Contents/Resources/AppIcon.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Tired of remembering multiple passwords? $GIVEN_NAME " >> $NOTIFY_LOG
echo "Command: MainText: We use single sign-on services to help you log in to each of our corporate services.
You can use your email address and account password to sign into all necessary applications." >> $NOTIFY_LOG
echo "Status: Setting the account password for your Mac to sync with your network password..." >> $NOTIFY_LOG
sleep 10
 
#3 - Self Service makes the Mac life easier
echo "Command: Image: /Applications/Self Service.app/Contents/Resources/AppIcon.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Self Service makes the Mac life easier" >> $NOTIFY_LOG
echo "Command: MainText: Self Service includes helpful bookmarks and installers for other applications that may interest you." >> $NOTIFY_LOG
echo "Status: Installing Jamf Self Service..." >> $NOTIFY_LOG
sleep 10
 
#4 - Everything you need for your first day
###Jamf Triggers
echo "Command: Image: /System/Library/CoreServices/Install in Progress.app/Contents/Resources/Installer.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Installing everything you need for your first day." >> $NOTIFY_LOG
echo "Command: MainText: All the apps you'll need today are already being installed. When setup is complete, you'll find that Microsoft Office, Slack, and Zoom are all ready to go. Launch apps from the Dock and have fun!" >> $NOTIFY_LOG
echo "Status: Installing Microsoft Office..." >> $NOTIFY_LOG
/usr/local/bin/jamf policy -event "InstallOffice"
sleep 5
 
#5 - Finishing up
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ApplicationsFolderIcon.icns" >> $NOTIFY_LOG
echo "Status: Installing Slack..." >> $NOTIFY_LOG
/usr/local/bin/jamf policy -event "InstallSlack"
sleep 5
echo "Status: Finishing up... We're almost ready for you, $GIVEN_NAME" >> $NOTIFY_LOG
sleep 3
 
###Clean Up
sleep 3
echo "Command: Quit" >> $NOTIFY_LOG
sleep 1
rm -rf $NOTIFY_LOG
 
#6 - Disable notify screen from loginwindow process
#Make policy? 
/usr/local/bin/authchanger -reset
/Applications/XCreds.app/Contents/Resources/xcreds_login.sh -i
sleep 1
shutdown -r now

EOS


# Script Permissions
chown root:wheel "${scriptLocation}"
chmod 777 "${scriptLocation}"
chmod u+x "${scriptLocation}"

# Set permissions for NoLoAD ScriptPath
defaults write "${prefFile}" ScriptPath "${scriptLocation}"
echo "ScriptPath set to:" >> "${log}"
defaults read "${prefFile}" ScriptPath >> "${log}"
sleep 1

# Hand-off to NoLoAD for Notify
${authchanger} -reset -AD -Notify -prelogin NoMADLoginAD:RunScript,privileged
echo "Rebooting with authorizationdb settings:" >> "${log}"
${authchanger} -print >> "${log}"
sleep 3
# Restart our device to kick the predeployment
shutdown -r now