
#!/bin/zsh

fpctl=/usr/bin/fileproviderctl
logFile=/private/var/log/OneDriveEviction.log

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
MappedStorage=($(find $userCloudStorage -depth 1 -type d))
logger "File Providers: ${#MappedStorage[@]}" 4

# Change the context to our logged in user.
for store in ${MappedStorage[@]}; do
	logger "Checking $store is a OneDrive provider..." 4
	
	OLDIFS=$IFS #Store our IFS
	IFS=$'\n' # Set IFS to line break
	
	if [[ $store == *"OneDrive"* ]]; then
		if [[ -d "$store/Desktop" ]]; then
			logger "Desktop is synced to OneDrive provider: $store" 4
			evictedFiles=($(find $store/Desktop -type f -exec ls -l% {} + | grep '%' | grep -v '.DS_Store' | while IFS= read -r line; do echo "$line"; done))
		fi
		
		logger "Scanning $store for materialised files" 3
		# Find locates all files and prints their full pathways
		# -exec then runs the subsequent command on all files found

#		materializedFiles=($(find $store -type f -exec ls -l% {} + | grep -v '%' | grep -v '.DS_Store' | while IFS= read -r line; do echo "$line"; done))
#		for file in ${materializedFiles[@]}; do
#			logger "Found materialized file: $file" 4
#			filePath=$(echo $file | awk '{for (start=9; start<=NF; start++) cols=cols $start " "; print cols}' | sed 's/[[:space:]]*$//')
#			logger "Attempting to evict $filePath" 3
#			#su - "$loggedInUser" -c "$fpctl evict "$filePath"" >> "$logFile"
#		done
		for file in ${evictedFiles[@]}; do
			logger "Found evicted file: $file" 4
			filePath=$(echo $file | awk '{for (start=9; start<=NF; start++) cols=cols $start " "; print cols}' | sed 's/[[:space:]]*$//')
			logger "Attempting to materialize $filePath" 3
			#su - "$loggedInUser" -c "$fpctl materialize "$filePath"" >> "$logFile"
		done
	fi
done

exit 0