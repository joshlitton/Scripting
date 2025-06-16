#!/bin/bash

homeFolders=$(ls /Users/)
userTemplateConfig="/Library/User Template/English.lproj/.FlashPrint5/config"

# This will be written to new files created
configContent="[general_]\nautoCheckUpdate=false"

UpdateConfig () {
	echo "Updating $1"
	sed -i '' 's/autoCheckUpdate=true/autoCheckUpdate=false/' $1
	#cat $1
}

CreateConfig () {
	echo "Creating $1"
	filePath="$1"
	# Check if the parent folder exists, if not create it
	if [[ ! -d ${filePath%/*} ]]; then
		mkdir -p "${filePath%/*}"
	fi
	# Write our template file
	printf "$2" > "$filePath"
}

for user in ${homeFolders[@]}; do
	configFile="/Users/$user/.FlashPrint5/config"
	# Skip any of the following users, or if the user folder starts with a "."
	if [[ $user == "jamfmanage" || $user == "Shared" || $user == "Library" || $user =~ ^\. ]]; then
		echo "Skipping $user"
	else
		if [[ -e ${configFile} ]]; then
			UpdateConfig ${configFile}
			chown "$user":staff ${configFile}
		else
			CreateConfig ${configFile} ${configContent}
			chown "$user":staff ${configFile%/*}
			chown "$user":staff ${configFile}
		fi
	fi
done

CreateConfig "${userTemplateConfig}" "${configContent}"
