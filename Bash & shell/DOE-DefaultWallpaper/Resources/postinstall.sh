#!/bin/bash
DefaultPicture="/System/Library/CoreServices/DefaultDesktop.heic"
MojaveBackground="/Library/Desktop Pictures/Mojave.heic"
DesktopPicture="/Library/Desktop Pictures/Mojave-Original.heic"
CurrentDesktop=$(/usr/local/bin/desktoppr)
os_ver=$(sw_vers -productVersion)

# get the current user
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

echo "Default picture is $DefaultPicture"
echo "Current Desktop is $CurrentDesktop" 

# Rename old desktop setup
if [[ -f "$DesktopPicture" ]]; then
    mv "/Library/Desktop Pictures/Mojave.heic" "/Library/Desktop Pictures/NFT-old.heic"
    mv "/Library/Desktop Pictures/Mojave-Original.heic" "/Library/Desktop Pictures/Mojave.heic"
fi

# call Outset login-once trigger 
if [[ -f "/usr/local/outset/outset" ]]; then
	echo "Outset detected, running login-once hook"
    sudo -u $loggedInUser /usr/local/outset/outset --login-once
fi

# Check for Mojave to fix existing deployment
if [[ "$os_ver" == 10.14.* ]]; then
    echo "Detected MacOS Mojave: $os_ver"
    # Set desktop back to CurrentDesktop if the user had changed it
    if [[ "$CurrentDesktop" != "$DefaultPicture"  ]] || [[ "$CurrentDesktop" != "$MojaveBackground"; then
        /usr/local/bin/desktoppr "$CurrentDesktop"
    fi
fi
exit 0