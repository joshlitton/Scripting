#!/bin/bash
server="https://a400-5b.pro.jamf.training"
authToken=$(curl -sk https://a400-5b.pro.jamf.training/api/v1/auth/token -X POST -H "Authorization: Basic YXBpX3VzZXI6amFtZjEyMzQ1Njc4OQ==")
api_token=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )
read -p "Enter a computer ID: " compId

# Write our stylesheet
cat << EOF > /tmp/stylesheet_applications.xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:template match="/">
<xsl:for-each select="computer/software/applications/application">
<xsl:value-of select="name"/>
<xsl:text>,</xsl:text>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
EOF
IFS=,
xml=$(curl -ks -X GET "${server}/JSSResource/computers/id/${compId}" \
-H "accept: application/xml" \
-H "Authorization: Bearer ${api_token}")

computerName=$(echo ${xml} | xmllint --xpath '/computer/general/name/text()' -)
installedApps=($(echo ${xml} | xsltproc /tmp/stylesheet_applications.xslt -))

for app in ${installedApps[@]}
do
	echo "${app} is installed on ${computerName}"
done	