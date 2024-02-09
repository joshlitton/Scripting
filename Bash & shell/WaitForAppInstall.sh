#!/bin/bash

waitForAppInstall () {
	count=0
	echo "=========================="
	echo "Validating $1"
	echo "=========================="
	while [[ ! -e "$1" ]]; do
		((count++))
		if [[ "$count" == *"0" ]]; then
			echo "Waiting for $1 to deploy..."
		fi
		sleep 1
	done
	echo "$1 deployed successfully."
}
waitForAppInstall "/var/tmp/file.txt"