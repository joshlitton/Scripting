#!/bin/zsh
# Make the script reusable with parameters
# Curl URL
csvURL="${4}"
logFile="${5}"

logger () { # Used to write logs to file
    logMessage="$1"
    logLevel="$2"
    timestamp=$(date +%F\ %T)

    # Log Level Prefix
    case "$logLevel" in 
        1 ) # ERROR
        logPrefix="ERROR"
        ;;
        2 ) # WARNING
        logPrefix="WARN "
        ;;
        3 ) # INFO
        logPrefix="INFO "
        ;;
        4 ) # DEBUG
        logPrefix="DEBUG"
        ;;
        9 ) # BREAK
        logPrefix="BREAK"
        ;;
    esac
	
    echo "$timestamp : $logPrefix >> $logMessage" >> "$logFile"
} #logger "Message goes here" 4
logger "######### Starting Script #########" 9
logger "URL: $csvURL" 4
logger "Log Path: $logFile" 4


mySerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/ {print $4}')
while IFS=',' read -r serial number asset; do
logger "Line data: $serial $number $asset" 4
    if [[ "$mySerial" == "$serial" ]]; then
        DeviceName="SCT-Loan-$number-$asset"
        logger "Setting Device Name to: $DeviceName" 3
        /usr/local/jamf/bin/jamf setComputerName -name "$DeviceName"
        exit 0
    else
    	logger "No match found. Next line..." 4
    fi
done < <(curl -s "$csvURL")

logger "Unable to find $mySerial in CSV" 2

exit 2
