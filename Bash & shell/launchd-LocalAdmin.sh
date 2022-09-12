#!/bin/bash

# Constants
scripts="/Library/Scripts/ACME"
daemon="/Library/LaunchDaemons/com.acme.createjamfit.plist"
if [[ -e "$scripts" ]]
then
  echo "Script library exists"
else
  echo "Creating Script Library"
  sudo mkdir "$scripts"
  sudo chmod 755 "$scripts"
fi


tee "$scripts/createJamfIT.sh" << EOL
#!/bin/bash

# Check account exists
result=$(sudo dscl . -list /Users | grep jamf_it)

# Check for jamf_it user account
if [[ $result = "jamf_it" ]]
then 
  #User Exists
  echo "Jamf IT Admin exists"
else
  #User Does Not exist
  echo "Jamf IT Admin doesn't exist"
  sudo /usr/local/bin/jamf policy -event createJamfAdmin
fi

# Check jamf_it is hidden
hidden=$(sudo dscl . -read /Users/jamf_it IsHidden | awk '{print $2}')

if [[ $hidden = 1 ]]
then
  echo "Jamf Admin account is hidden"
else
  sudo dscl . -create /Users/jamf_it IsHidden 1
  sleep 0.5
  /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -description "Please do not tamper with the jamf_it account" -icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns -button1 "Acknowledge"
fi


# Check for admin membership
member=$(sudo dseditgroup -o checkmember -m jamf_it admin | awk '{print $1}')

if [[ $member = "no" ]]
then 
  echo "User is not a member of admins, updating"
  #sudo dscl . -append /Groups/admin GroupMembership jamf_it 
  sudo dseditgroup -o edit -a jamf_it -t user -L admin
  sleep 0.5
  /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -description "Please do not tamper with the jamf_it account" -icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns -button1 "Acknowledge"
else 
  echo "Jamf_IT is a local admin"
fi
EOL

chmod 755 "$scripts/createJamfIT.sh"
chmod +x "$scripts/createJamfIT.sh"


tee "$daemon" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.acme.createjamfit</string>
  <key>ProgramArguments</key>
  <array>
    <string>sh</string>
    <string>-c</string>
    <string>/Library/Scripts/ACME/createJamfIT.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>30</integer>
    <key>Weekday</key>
    <integer>1</integer>
  </dict>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

chown root:wheel "$daemon"
chmod 644 "$daemon"