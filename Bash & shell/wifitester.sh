#!/bin/sh
for i in {1..60}; do 
	connected=$(sudo /usr/bin/profiles show | grep "WiFi - Migration")
	if [[ $connected != $null ]]; then
		echo "WiFi profile has arrived! Rebooting..."
		sleep 1
		exit 0
		#shutdown -r now
	fi
	echo "WiFi profile has not arrived, waiting 5 seconds"
	sleep 5
done
echo "Timed out..."
exit 2