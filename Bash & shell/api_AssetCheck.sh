#!/bin/bash

jamfURL="https://ae400-5b.pro.jamf.training"
jh="/Library/Application Support/Jamf/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
#Establish empty array
matchedDevices=()

authToken=$(curl -sk ${jamfURL}/api/v1/auth/token -X POST -H "Authorization: Basic amFtZmFkbWluOm1lZ2FuZVJTMjgw")
api_token=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )

#read -p "Enter the device AssetID: " userEnteredTag
userEnteredTag=$(osascript -e 'text returned of (display dialog "Enter the asset tag of lost device" default answer "JS100144" buttons {"Submit"} default button 1)')
echo "User entered ${userEnteredTag}"

# Collect all of the IDs
q=$(curl -sk -X GET "${jamfURL}/JSSResource/mobiledevices" \
-H "accept: application/xml" \
-H "Authorization: Bearer ${api_token}")

# Validate the data
#echo ${q} | xmllint --format -


# Write a stylesheet? 
# Collect these attributes: Id, Asset_Tag, Username, Building, Department, 
cat << EOF > /tmp/stylesheet.xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:template match="/">
<xsl:for-each select="mobile_device/general">
<xsl:value-of select="id"/>
<xsl:text>,</xsl:text>
<xsl:value-of select="asset_tag"/>
<xsl:text>,</xsl:text>
</xsl:for-each>
<xsl:for-each select="mobile_device/location">
<xsl:value-of select="username"/>
<xsl:text>,</xsl:text>
<xsl:value-of select="building"/>
<xsl:text>,</xsl:text>
<xsl:value-of select="department"/>
<xsl:text>&#xa;</xsl:text>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
EOF

# Collect all mobile device IDs 
mobileDeviceIds=($(echo ${q} | xmllint --format - | awk -F '[<>]' '/<id>/{print $3}'))

for id in ${mobileDeviceIds[@]}
do
	# Get the details of each device matching user entered asset tag
	# Array Fields should be: id,asset_tag,username,building,department
	IFS=,
	deviceInfo=($(curl -sk -X GET "${jamfURL}/JSSResource/mobiledevices/id/${id}" \
-H "accept: application/xml" \
-H "Authorization: Bearer ${api_token}" | xsltproc "/tmp/stylesheet.xslt" -))
	#Confirm data is in an array
	#echo ${deviceInfo[1]}
	IFS=""
	if [[ ${deviceInfo[1]} = ${userEnteredTag} ]]
	then 
		# Add each matched device to an array as a single line item. 
		matchedDevices+=("${deviceInfo[0]},${deviceInfo[1]},${deviceInfo[2]},${deviceInfo[3]},${deviceInfo[4]}")
	fi
done
# Confirm the devices data was added to array as line items
#echo "${matchedDevices[1]}"
# Get the count of devices
deviceCount="${#matchedDevices[@]}"

if [[ ${deviceCount} = 0 ]]
then 
	osascript -e 'display dialog "No devices found matching entered asset tag: '"${userEnteredTag}"'" buttons {"Finish"} default button 1'
else
	for entry in ${matchedDevices[@]}
	do
		text="${text},${entry}"
	done
		echo ${text[@]}
download=$(osascript -e 'display dialog "Found '"${deviceCount}"' devices matching asset tag: '"${userEnteredTag}"' '"${text}"' " buttons {"Download", "Exit"} default button 1')

	if [[ ${download} = "button returned:Download" ]]
		then
			echo "${text[@]}" > "/Users/Shared/Search Results.txt"
	fi
fi