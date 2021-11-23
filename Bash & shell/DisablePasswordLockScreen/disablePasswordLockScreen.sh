#!/bin/sh

# Set delay to ask for password when locked to 0 (Disabled)
# Setting is a user based preference ~/Library/Preferences
defaults -currentHost write com.apple.screensaver askForPasswordDelay -int 0

exit 0
