#!/bin/sh
ME="$(id -un)"

USERPREF="/Users/$ME/Library/Preferences/"
PLIST1="$USERPREF""com.apple.TextInputMenu.plist"
PLIST2="$USERPREF""com.apple.HIToolbox.plist"

echo "Turning Off Menu Item"
defaults write "$PLIST1" visible -bool false
sleep 0.5
/usr/libexec/plistbuddy -c "Add :AppleEnabledInputSources:1:InputSourceKind string 'Keyboard Layout'" "$PLIST2"
/usr/libexec/plistbuddy -c "Add :AppleEnabledInputSources:1:KeyboardLayout\ ID integer -18944" "$PLIST2"
/usr/libexec/plistbuddy -c "Add :AppleEnabledInputSources:1:KeyboardLayout\ Name string 'Greek'" "$PLIST2"
sleep 0.5
echo "Turning On Menu Item"
defaults write "$PLIST1" visible -bool true

echo "If this is your first time logging in - you may need to reboot to enable Greek Language"

chown "$ME" "$PLIST1"
chown "$ME" "$PLIST2"
