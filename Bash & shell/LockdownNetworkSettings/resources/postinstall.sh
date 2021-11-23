#!/bin/sh

# Check the Machine Model,Create Network Locations and Set Network Settings
wifi=(`networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/,/Ethernet/' | awk 'NR==2' | cut -d " " -f 2` )


# Creates the Network Location

# networksetup -createlocation "SITE" populate
# networksetup -switchtolocation "SITE"

sleep 4

if [[ $wifi == "en0" ]]; then

#   networksetup -setwebproxy "Thunderbolt Ethernet" 127.0.0.1 8079
#   networksetup -setsecurewebproxy "Thunderbolt Ethernet"127.0.0.1 8079
#   networksetup -setftpproxy "Thunderbolt Ethernet" 127.0.0.1 8079
#   networksetup -setsocksfirewallproxy "Thunderbolt Ethernet" 127.0.0.1 8079
#   networksetup -setproxybypassdomains "Thunderbolt Ethernet" *.local 169.254/16 *.dpi.wa.gov.au
#   networksetup -setproxyautodiscovery Wi-Fi on
#   networksetup -setproxybypassdomains Wi-Fi *.local 169.254/16 *.dpi.wa.gov.au
#   networksetup -ordernetworkservices Wi-Fi "Thunderbolt Ethernet" "Bluetooth DUN" "Bluetooth PAN" "Thunderbolt Bridge"
    /usr/libexec/airportd en0 prefs RequireAdminNetworkChange=YES RequireAdminPowerToggle=YES RequireAdminIBSS=YES

  
else

#   networksetup -setwebproxy Ethernet 127.0.0.1 8079
#   networksetup -setsecurewebproxy Ethernet 127.0.0.1 8079
#   networksetup -setftpproxy Ethernet 127.0.0.1 8079
#   networksetup -setsocksfirewallproxy Ethernet 127.0.0.1 8079
#   networksetup -setproxybypassdomains Ethernet *.local 169.254/16 *.dpi.wa.gov.au
#   networksetup -setproxyautodiscovery Wi-Fi on
#   networksetup -setproxybypassdomains Wi-Fi *.local 169.254/16 *.dpi.wa.gov.au
    /usr/libexec/airportd en1 prefs RequireAdminNetworkChange=YES RequireAdminPowerToggle=YES RequireAdminIBSS=YES

  
fi



#Get the active network location 'set' -
#CURRENTSET=$(/usr/libexec/PlistBuddy -c 'print:CurrentSet' /Library/Preferences/SystemConfiguration/preferences.plist | awk -F\/ '{print $3}')

#Get the first/top interface in the list which should now be WiFi -
#CURRENTINTERFACE=$(/usr/libexec/PlistBuddy -c 'print:Sets:'$CURRENTSET':Network:Global:IPv4:ServiceOrder:0' /Library/Preferences/SystemConfiguration/preferences.plist)

#Set the key for "ExcludeSimpleHostnames", this is the part that needs root -
#/usr/libexec/PlistBuddy -c 'add:NetworkServices:'$CURRENTINTERFACE':Proxies:ExcludeSimpleHostnames integer 1' /Library/Preferences/SystemConfiguration/preferences.plist

# network->resetLocations
#echo 'network->resetLocations' 
#networksetup -deletelocation "Automatic"


# END

exit 0
