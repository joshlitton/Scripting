#!/bin/bash

iconscli="/Applications/Icons.app/Contents/MacOS/icons_cli"

apps=(`ls /Applications/`)
outputPath="/Users/josh.litton/Desktop/icons"
for app in $apps; do
	iconName=$(echo ${app} | sed -e 's/ //' | tr '[:upper:]' '[:lower:]' | sed -e 's/\.app//')
	appPath="/Applications/${app}"
	#echo "$iconscli will be exporting ${appPath} to ${outputPath}/${iconName}"
	$iconscli -x au -n ${iconName} -i ${appPath} -o ${outputPath}
	
done