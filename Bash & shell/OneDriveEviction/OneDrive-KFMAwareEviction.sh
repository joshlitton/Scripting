#!/bin/zsh

materialize=true
fpctl=/usr/bin/fileproviderctl
logFile=/private/var/log/OneDriveEviction.log

oldIFS=$IFS
IFS=$'\n'	

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

if [[ $(find "/Users/$loggedInUser/Desktop" -type l -maxdepth 0 -ls | grep "OneDrive") ]]; then
	desktopMoved=true
	logger "Desktop has been moved by KFM" 4
else 
	desktopMoved=false
	logger "Desktop has NOT been moved by KFM" 4
fi
MappedStorage=($(find "${userCloudStorage}" -depth 1 -type d))
logger "File Providers: ${#MappedStorage[@]}" 4

for store in ${MappedStorage[@]}; do
	logger "Checking $store is a OneDrive provider..." 4
	#OLDIFS=$IFS #Store our IFS
	#IFS=$'\n' # Set IFS to line break
	if [[ $store == *"OneDrive"* ]]; then
		
		folders=($(find "${store}" -depth 1 -type d))
		logger "Found $(echo ${#folders[@]}) folders in root of $store" 3
		files=($(find "${store}" -depth 1 -type f))
		logger "Found $(echo ${#files[@]}) files in root of $store" 3
	
		for folder in ${folders[@]}; do
			logger "Processing: $folder" 3
			echo "$folder == ${store}/Desktop"
				if [[ "$folder" == "${store}/Desktop" ]]; then
					if [[ $desktopMoved == true && $materialize == true ]]; then
						logger "Desktop is synced to store: $store" 3
						logger "Running materialize on: $store/Desktop" 3
						echo 'su - ${loggedInUser} -c "$fpctl materialize '"${folder}"' >> "$logFile"'
					else
						logger "Desktop has not been moved or Materialize flag not enabled." 2
						logger "Evicting: ${folder}" 3
						echo 'su - ${loggedInUser} -c "$fpctl evict -n '"${folder}"' >> "$logFile"'
					fi
				else 
					logger "Evicting: ${folder}" 3
					echo 'su - ${loggedInUser} -c "$fpctl evict -n '"${folder}"' >> "$logFile"'
				fi
		done
		for file in ${files[@]}; do 
			logger "Evicting: ${file}" 3
			echo 'su - ${loggedInUser} -c "$fpctl evict '"${file}"' >> "$logFile"'
		done
	fi
done