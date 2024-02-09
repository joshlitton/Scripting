#!/bin/zsh
# Restricts creation of ad-hoc networks to admins. 
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport prefs RequireAdminIBSS=YES 
# Restricts power on/off of Wi-Fi to admins. 
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport prefs RequireAdminPowerToggle=YES 
# Restricts network changes to admins. 
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport prefs RequireAdminNetworkChange=YES 

exit 0
