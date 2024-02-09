#!/bin/bash

localFile="/etc/pam.d/sudo_local"
jamfHelper="/Library/Application Support/Jamf/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

CreateSudoLocal () {
	tee "$1" << EOF
# Enables TouchID auth for sudo - persistent between system updates
auth	sufficient	pam_tid.so
EOF
}

if [[ -f "${localFile}" ]]; then
	echo "File exists"
	"${jamfHelper}" \
	-windowType utility \
	-title Warning \
	-description "If you have made changes to your /etc/sudo_local file, these will be overwritten" \
	-icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns" \
	-button1 "Proceed" \
	-button2 "Cancel" \
	-defaultButton 1 \
	-cancelButton 2
	if [[ $? == 0 ]]; then
		mv "${localFile}" "${localFile}-$(date "+%Y%m%d").bak"
		CreateSudoLocal ${localFile}
	else
		echo "User cancelled the prompt"
		exit 1
	fi
else
	echo "File doesn't exist, creating..."
	CreateSudoLocal ${localFile}
fi