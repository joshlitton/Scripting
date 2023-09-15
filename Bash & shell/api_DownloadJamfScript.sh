#!/bin/bash

token=$(curl -sk https://sbcwa.jamfcloud.com/api/v1/auth/token -X POST -H "Authorization: Basic amFtZl9hcGlfdXNlcjpYSkFCWm1jYkdwV0UzQTlK")
api_token=$(/usr/bin/plutil -extract token raw - <<< "$token")

json=$(curl -sk "https://sbcwa.jamfcloud.com/api/v1/scripts?filter=name%3D%3D%22launchDaemon-SwiftDialog%22" -X GET \
-H "accept: application/json" \
-H "Authorization: Bearer ${api_token}")

#echo $json
script=$(plutil -extract results.0.scriptContents raw -o - - <<< "$json")

echo "$script" | sudo bash

#scriptID=$(echo ${xml}  | xmllint --xpath )