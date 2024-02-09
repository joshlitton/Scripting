#!/bin/sh
## postinstall

# pathToScript=$0
# pathToPackage=$1
# targetLocation=$2
# targetVolume=$3
# wifi=$4
SSID="GGS"

wifiDevice=$(/usr/sbin/networksetup -listallhardwareports | awk '/^Hardware Port: Wi-Fi/,/^Ethernet Address/' | grep "Device" | awk '{print $2}')

if [[ $(/usr/sbin/networksetup -listpreferredwirelessnetworks "$wifiDevice" | grep "${SSID}" | awk '{print $1}') ]]; then 
    echo "SSID: $SSID found, removing."
    #/usr/sbin/networksetup -removepreferredwirelessnetwork "$wifiDevice" "$SSID"
else 
    echo "SSID: $SSID not found, exiting script"
fi

exit 0		## Success
exit 1		## Failure