#!/bin/zsh
# Make the script reusable with parameters
# Curl URL
csvURL="${4}"
# Improvements?
# Suffix
# Prefix
# Which Columns to use as suffix/prefix
mySerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/ {print $4}')
while IFS=',' read -r serial number asset; do
    if [[ "$mySerial" == "$serial" ]]; then
        DeviceName="SCT-Loan-$number-$asset"
        echo "Setting Device Name to: $DeviceName"
        #/usr/local/jamf/bin/jamf setComputerName -name "$DeviceName"
    fi
done < <(curl -s "$csvURL")
exit 
