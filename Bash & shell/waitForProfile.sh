#!/bin/zsh
profileName="WiFi - SBC Devices (Migration)"

if [[ -z $profileName ]]; then
	echo "Blank parameter, exiting"
	exit 2
else
	for i in {1..60}; do 
		connected=$(/usr/bin/profiles show | grep "${profileName}")
		echo "Value of connected is: $connected"
		if [[ -z $connected ]]; then
			echo "Profile has not arrived, waiting 5 seconds"
			sleep 5
		else
			echo "${profileName} profile has arrived!"
			exit 0
		fi
	done
	echo "Timed out..."
	exit 1
fi