#!/bin/zsh
version="0.1.3d"
fpctl=/usr/bin/fileproviderctl
logFile=/private/var/log/OneDriveEviction.log
evictedFiles=()

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
logger "Version: ${version}" 3
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
	logger "No user logged in at runtime, exiting" 2
    exit 1
fi	
logger "Got logged in user: $loggedInUser" 3
userCloudStorage="/Users/$loggedInUser/Library/CloudStorage"
logger "Got cloud storage locale: $userCloudStorage" 4
MappedStorage=($(find $userCloudStorage -depth 1 -type d))
logger "File Providers: ${#MappedStorage[@]}" 4

# Change the context to our logged in user.
for store in ${MappedStorage[@]}; do
	logger "Checking $store is a OneDrive provider..." 4
	if [[ $store == *"OneDrive"* ]]; then
		logger "Scanning $store for materialised files" 3
		# Find locates all files and prints their full pathways
		# -exec then runs the subsequent command on all files found
		OLDIFS=$IFS #Store our IFS
		IFS=$'\n' # Set IFS to line break
		files=($(find $store -type f -exec ls -l% {} + | grep -v '%' | grep -v '.DS_Store' | while IFS= read -r line; do echo "$line"; done))
		for file in ${files[@]}; do
			logger "Found materialized file: $file" 4
			filePath=$(echo $file | awk '{for (start=9; start<=NF; start++) cols=cols $start " "; print cols}' | sed 's/[[:space:]]*$//')
			logger "Attempting to evict $filePath" 3
			/usr/bin/su -l "$loggedInUser" -c "${fpctl} evict \"${filePath}\""
            if [[ $? -lt 1 ]]; then 
            	evictedFiles+=("${filePath}")
            fi
		done
	fi
done
logger "Evicted Files: " 3
for eviction in ${evictedFiles[@]}; do
	echo "${eviction}" >> $logFile
done
exit 0