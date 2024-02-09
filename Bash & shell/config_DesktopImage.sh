#!/bin/zsh
# Written by Josh Litton
# Copyright (c) Catalytic IT 2023

# Variables
backgroundImg=${4:-"/Library/Management/Images/org-background.jpeg"} # Path to background image [default: "/Library/Management/Images/org-background.jpeg"]
desktoppr="/usr/local/bin/desktoppr"

# Get logged in user information
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# Run as user
/usr/bin/su -l "${loggedInUser}" -c "${desktoppr} all \"${backgroundImg}\""

exit 0