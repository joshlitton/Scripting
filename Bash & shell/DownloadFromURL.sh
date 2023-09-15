#!/bin/zsh
fileURL=${4:?No URL Entered}
localName=${5:-"keep"}
logFile=${6:-"/private/var/log/college-office-templates.log"}
tempDirectory="/var/tmp/"
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
templateFolder="/Users/$loggedInUser/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized/"

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
	esac
	
	echo "$timestamp : $logPrefix >> $logMessage" >> $logFile
} #logger "Message goes here" 4


downloadFile () {
	curl --silent $1 --output-dir $tempDirectory
}

curl "https://templates.ufcc.wa.edu.au:8443/ufcc-word-template.dotx" --output "/Users/Shared/UFCC - College Template.dotx"