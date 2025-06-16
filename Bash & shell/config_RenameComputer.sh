#!/bin/sh
namePrefix=${4} #Hostname Prefix [ Example: "SBC", can be left blank ]
nameDelim1=${5} #Delimiter 1 [ Example: "-", can be left blank ]
nameMiddle=${6} #Hostname Middle [ Options: "serial", "wifimac", "username" or custom text]
nameDelim2=${7} #Delimiter 2 [ Example: "-", can be left blank ]
nameSuffix=${8} #Hostname Suffix [ Example: "Staff", can be left blank ]

case $nameMiddle in
    serial)
        echo "Detected main hostname middle as predefined option: Serial Number"
        hostnameMiddle=$(system_profiler SPHardwareDataType | grep Serial | awk '{ print $4}')
        ;;
    wifimac)
        echo "Detected main hostname middle as predefined option: Mac Address"
        hostnameMiddle=$(/usr/sbin/networksetup -listallhardwareports | awk '/^Hardware Port: Wi-Fi/,/^Ethernet Address/' | grep "Ethernet" | awk '{print $3}' | sed 's/://g')
        ;;
    username)
    	echo "Detected main hostname middle as predefined option: Username of logged in user"
        hostnameMiddle=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
        ;;
    *)
        echo "Predefined option not detected, using custom text: ${nameMiddle}"
        hostnameMiddle="${nameMiddle}"
        ;;
esac

#Computer Name
newName="${namePrefix}${nameDelim1}${hostnameMiddle}${nameDelim2}${nameSuffix}"
echo "Setting device name to: ${newName}"
/usr/local/jamf/bin/jamf setComputerName -name "${newName}"