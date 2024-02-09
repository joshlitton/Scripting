#!/bin/zsh

outputFile="/Users/josh.litton/Desktop/ComputerAssessment.txt"
edgeProfileLocale="/Users/josh.litton/Library/Application Support/Microsoft Edge"
IFS=$'\n'
edgeProfiles=($(ls "${edgeProfileLocale}" | grep -E '^Profile [0-9]{1,}'))
for profile in ${edgeProfiles[@]}; do
	#echo "${profile}" 
	plutil -extract "account_info".0."email" raw "${edgeProfileLocale}/${profile}/Preferences"
done

exit 0
# Setup MacBook - Personal
echo "===================================" >> $outputFile
echo "Starting Collection..." > $outputFile
echo "===================================" >> $outputFile
echo "Applications" >> $outputFile
echo "===================================" >> $outputFile
ls /Applications >> $outputFile
echo "Utilities" >> $outputFile
echo "===================================" >> $outputFile
ls /Applications/Utilities/ >> $outputFile

#find /Applications -type d -depth 1 >> $outputFile
#find /Applications/Utilities -type d -depth 1 >> $outputFile
