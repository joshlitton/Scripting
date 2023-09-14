#!/bin/zsh

providerExtID="com.microsoft.OneDrive.FileProvider"
fp="/usr/bin/fileproviderctl"
logFile="/private/var/log/FileProviderUtil.log"

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


logger "STARTING SCRIPT" 3
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
logger "Got logged in user: $loggedInUser" 3
userCloudStorage="/Users/$loggedInUser/Library/CloudStorage"
logger "Got cloud storage locale: $userCloudStorage" 4
CloudStores=($(su - "$loggedInUser" -c "find $userCloudStorage -depth 1 -type d"))
logger "File Providers: ${#CloudStores[@]}" 4

#for store in ${CloudStores[@]}; do 
#	logger "File Provider: ${store}" 4
#	xattr -l ${store}
#	#namespace=$(fileproviderctl attributes ${store} | grep "NSURLNameKey"| awk '{print $2}')
#	#fpdomain="${providerExtID}/${namespace}"
#	logger "Associated Domain: $fpdomain" 4
#	#su - "$loggedInUser" -c "$fp evict -n $store"
#	#su - "$loggedInUser" -c "$fp stabilize $fpdomain"
#done

activeProviders=($(${fp} listproviders | grep "$providerExtID"))



echo "${activeProviders[@]}"



# Show evictable files
#echo "Enumerate Pending"
#$fp enumerate pending ${activeProviders[0]} -e
#echo "Enumerate Materialized"
#$fp enumerate materialized ${activeProviders[0]} -ev

#$fp ls evict -u

#$fp evict -n "/Users/TESTT7/Library/CloudStorage/OneDrive-SharedLibraries-PLCScotch/Scotch - SCT Scott Class - General"
#$fp materialize "/Users/TESTT7/Library/CloudStorage/OneDrive-SharedLibraries-PLCScotch/Scotch - SCT Scott Class - General"
#$fp evaluate "/Users/TESTT7/Library/CloudStorage/OneDrive-SharedLibraries-PLCScotch/Scotch - SCT Scott Class - General"
#$fp check ${activeProviders[0]} -o ~/.fpcheck.txt
#$fp signal ${activeProviders[0]}
$fp attributes ${activeProviders[0]}

$fp stabilize ${activeProviders[0]}