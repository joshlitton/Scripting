#!/bin/zsh
# Create your VPN connection information on a test machine, copy the file path below
# Delete the contents of the plist only retaining the "Profiles" dictionary
# Save and deploy the plist to your endpoints to a temporary path
FortiConfigPlist="/Library/Application Support/Fortinet/FortiClient/conf/vpn.plist"
vpnProfilesPlist="/private/var/tmp/company-vpns.plist"

# We need to create the plist initially - setting this to doso:
defaults write "${FortiConfigPlist}" EnableSSL -int 1
# Blocks Creation of additional connections if desired
defaults write "${FortiConfigPlist}" DisallowPersonalVPN -int 1
sleep 1.0
/usr/libexec/PlistBuddy -x -c "Merge /Users/josh.litton/Desktop/trinity-vpn.plist" "${FortiConfigPlist}"

chown root:admin "${FortiConfigPlist}"
chmod 644 "${FortiConfigPlist}"

# Purge the plist if desired
rm -f "${vpnProfilesPlist}"

exit 0