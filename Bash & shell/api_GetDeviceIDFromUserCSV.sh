#!/bin/bash
csv="/Users/josh.litton/Desktop/sct_o365_dyn_license_A3_Faculty_2023-4-6.csv"
outFile="/tmp/SCT-A3UsersWithMacOS.csv"
header="Authorization: Basic <BASE64GOESHERE>"

token=$(curl -sk https://jss.plcscotch.wa.edu.au:8443/api/v1/auth/token -X POST -H "${header}")
api_token=$(/usr/bin/plutil -extract token raw - <<< "$token")

bearer="Authorization: Bearer ${api_token}"

json=$(curl -X GET "https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory?section=USER_AND_LOCATION&page=0&page-size=1&sort=id%3Aasc&filter=userAndLocation.email%3D%3D%22natalie.dimasi%40scoch.wa.edu.au%22" -H "${bearer}" -H "accept: application/json")

id=$(/usr/bin/plutil -extract results.0.id raw - <<< "$json")

echo "UserPrincipalName,JSSID" >> "$outFile"
cat "${csv}" | cut -d ',' -f 2 | while read UPN; do
	apiFormatedUPN=$(printf "$UPN" | sed 's/\@/\%40/g')
	json=$(curl -X GET "https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory?section=USER_AND_LOCATION&page=0&page-size=1&sort=id%3Aasc&filter=userAndLocation.email%3D%3D%22${apiFormatedUPN}%22" -H "${bearer}" -H "accept: application/json")
	
	id=$(/usr/bin/plutil -extract results.0.id raw - <<< "$json")
	
	if [[ "$id" =~ ^[0-9]{1,}$ ]]; then
		echo "${UPN},${id}" >> "$outFile"
	else
		echo "${UPN},No Device Found" >> "$outFile"
	fi
	
done