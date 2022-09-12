#!/bin/bash

# Constants
launchD="/Library/LaunchDaemons/com.litlabs.JamfServerCleanUp.plist"
scriptFile="/Library/Scripts/LitLabs/JamfServerCleanup.sh"

# Create the script folder if its not there
if [[ ! -e "/Library/Scripts/LitLabs/" ]] 
then
	mkdir "/Library/Scripts/LitLabs/"
fi
	

# Write our xml stylesheet
cat << EOF > /tmp/stylesheet.xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:template match="/">
<xsl:for-each select="policy/general">
<xsl:value-of select="id"/>
<xsl:text>,</xsl:text>
<xsl:value-of select="enabled"/>
<xsl:text>,</xsl:text>
</xsl:for-each>
<xsl:for-each select="policy/scope">
<xsl:value-of select="all_computers"/>
<xsl:text>&#xa;</xsl:text>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
EOF


## Start of Script
tee "${scriptFile}" <<\EOS
jamfURL="https://ae400-5b.pro.jamf.training"
authToken=$(curl -sk ${jamfURL}/api/v1/auth/token -X POST -H "Authorization: Basic YXBpX3VzZXI6amFtZjEyMzQ1Njc4OQ==")
api_token=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )

apiCall=$(curl -sk -X GET "${jamfURL}/JSSResource/policies" \
-H "accept: application/xml" \
-H "Authorization: Bearer ${api_token}")

policyIds=($(echo ${apiCall} | xmllint --format - | awk -F '[<>]' '/<id>/{print $3}'))

# Loop through the found policy IDs
for id in ${policyIds[@]}
do
	# Messages for debug
	#echo "Processing policy ID ${id}"
	xml=$(curl -sk -X GET "${jamfURL}/JSSResource/policies/id/${id}" \
-H "accept: application/xml" \
-H "Authorization: Bearer ${api_token}")
	
	# Compare our against stylesheet & store in an array
	oldIFS=$IFS
	IFS=,
	policy=($(echo ${xml} | xsltproc "/tmp/stylesheet.xslt" -))
	
	#id,enabled,allcomputersscoped
	echo ${policy[@]}
	if [[ ${policy[1]} == "false" ]]
	then
		#Set to disabled
		echo "Assigning Disabled category"
		curl -sk -X PUT "${jamfURL}/JSSResource/policies/id/${policy[0]}" \
		-H "accept: application/xml" \
		-H "Content-type: application/xml" \
		-H "Authorization: Bearer ${api_token}" \
		-d "<policy><general><category><name>Disabled Policies</name></category></general></policy>"
		
	elif [[ ${policy[2]} == "true" ]]
	then
		#Set to Global
		echo "Assigning Global category"
		curl -sk -X PUT "${jamfURL}/JSSResource/policies/id/${policy[0]}" \
		-H "accept: application/xml" \
		-H "Content-type: application/xml" \
		-H "Authorization: Bearer ${api_token}" \
		-d "<policy><general><category><name>Global Policies</name></category></general></policy>"
	fi
	
	# Write to file for testing
	#echo ${xml} | xmllint --format - > "/Users/student/Desktop/xml.xml"
done
EOS

## Start of LaunchDaemon
tee "${launchD}" << EOD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.litlabs.jamfservercleanup</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>-c</string>
		<string>/Library/Scripts/LitLabs/JamfServerCleanup.sh</string>
	</array>
	<key>StartCalendarInterval</key>
	<dict>
		<key>Hour</key>
		<integer>21</integer>
		<key>Minute</key>
		<integer>15</integer>
		<key>Weekday</key>
		<integer>5</integer>
	</dict>
</dict>
</plist>
EOD

# Setup our ownership and permissions
chown root:wheel "${launchD}"
chmod 644 "${launchD}"
chmod 755 "${scriptFile}"
chmod +x "${scriptFile}"

# Bootstrap that bad boy
launchctl bootstrap system /Library/LaunchDaemons/com.litlabs.JamfServerCleanUp.plist