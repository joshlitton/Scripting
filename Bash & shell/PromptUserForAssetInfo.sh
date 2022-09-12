#!/bin/bash
# Define variables
assetTag=""
selectedSite=""

## Prompt user to select the site
selectedSite=$(osascript << EOF
set buildings to {"Minneapolis", "Eu Claire", "London"}
set defaultBuilding to choose from list buildings with prompt "Select your location:" default items {"Minneapolis"} 
EOF
)
#Site we collected
#echo $selectedSite

#####################
# Minneapolis Logic #
#####################
if [[ $selectedSite = "Minneapolis" ]]
then
	echo "User selected ${selectedSite}"
	# Until the asset tag returned matches regex, keep prompting
	until [[ $assetTag =~ ^MSP-[0-9]{4}$ ]]
	do
		# Prompt user for Asset Tag
		assetTag=$(osascript << EOP
text returned of (display dialog "Enter device asset tag:" default answer "MSP-####" buttons {"Submit"} default button 1 with icon note)
EOP
)
		# Lets give the user a reason why we are pestering
		if [[ ! $assetTag =~ ^MSP-[0-9]{4}$ ]]
		then
			osascript -e 'display dialog "Format Error: \nPlease use correct formatting for '${selectedSite}' devices.\neg. MSP-1234" buttons {"Ok"} default button 1 with icon caution'
		fi
	done
###################
# Eu Claire Logic #
###################
elif [[ $selectedSite = "Eu Claire" ]]
then
	echo "User selected ${selectedSite}"
	# Until the asset tag returned matches regex, keep prompting
	until [[ $assetTag =~ ^EC-[0-9]{5}$ ]]
	do
		# Prompt user for Asset Tag
		assetTag=$(osascript << EOP
text returned of (display dialog "Enter device asset tag:" default answer "EC-#####" buttons {"Submit"} default button 1 with icon note)
EOP
)
		# Lets give the user a reason why we are pestering
		if [[ ! $assetTag =~ ^EC-[0-9]{5}$ ]]
		then
			osascript -e 'display dialog "Format Error: \nPlease use correct formatting for '"${selectedSite}"' devices.\neg. EC-12345" buttons {"Ok"} default button 1 with icon caution'
		fi
	done
	
################
# London Logic #
################
elif [[ $selectedSite = "London" ]]
then
	echo "User selected ${selectedSite}"
	# Until the asset tag returned matches regex, keep prompting
	until [[ $assetTag =~ ^[0-9]{8}$ ]]
	do
		# Prompt user for Asset Tag
		assetTag=$(osascript << EOP
text returned of (display dialog "Enter device asset tag:" default answer "########" buttons {"Submit"} default button 1 with icon note)
EOP
)
		# Lets give the user a reason why we are pestering
		if [[ ! $assetTag =~ ^[0-9]{8}$ ]]
		then
			osascript -e 'display dialog "Format Error: \nPlease use correct formatting for '${selectedSite}' devices.\neg. ########" buttons {"Ok"} default button 1 with icon caution'
		fi
	done
fi

echo "Submitting ${assetTag} to Jamf"
# Recon the asset tag to our server
sudo /usr/local/bin/jamf recon -assetTag "${assetTag}"
