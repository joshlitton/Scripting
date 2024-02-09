#!/bin/bash

url="https://sbcwa.jamfcloud.com"

authToken=$(curl -sk ${url}/api/v1/auth/token -X POST -H "Authorization: Basic amFtZl9hcGlfdXNlcjpYSkFCWm1jYkdwV0UzQTlK")
api_token=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )

#echo $api_token

curl --request POST \
--url https://sbcwa.jamfcloud.com/api/preview/mdm/commands \
--header "Authorization: Bearer ${api_token}" \
--header 'accept: application/json' \
--header 'content-type: application/json' \
--data '
{
		"clientData": [
				{
						"managementId": "9057ce59-4216-4226-8395-37b1397d379b"
				}
		],
		"commandData": {
				"commandType": "ERASE_DEVICE",
				"returnToService": {
						"enabled": true,
						"wifiProfileData": "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHBsaXN0IFBVQkxJQyAiLS8vQXBwbGUvL0RURCBQTElTVCAxLjAvL0VOIiAiaHR0cDovL3d3dy5hcHBsZS5jb20vRFREcy9Qcm9wZXJ0eUxpc3QtMS4wLmR0ZCI+CjxwbGlzdCB2ZXJzaW9uPSIxLjAiPgo8ZGljdD4KCTxrZXk+RHVyYXRpb25VbnRpbFJlbW92YWw8L2tleT4KCTxpbnRlZ2VyPjM2MDA8L2ludGVnZXI+Cgk8a2V5PlBheWxvYWRDb250ZW50PC9rZXk+Cgk8YXJyYXk+CgkJPGRpY3Q+CgkJCTxrZXk+QXV0b0pvaW48L2tleT4KCQkJPHRydWUvPgoJCQk8a2V5PkNhcHRpdmVCeXBhc3M8L2tleT4KCQkJPGZhbHNlLz4KCQkJPGtleT5EaXNhYmxlQXNzb2NpYXRpb25NQUNSYW5kb21pemF0aW9uPC9rZXk+CgkJCTx0cnVlLz4KCQkJPGtleT5FbmNyeXB0aW9uVHlwZTwva2V5PgoJCQk8c3RyaW5nPkFueTwvc3RyaW5nPgoJCQk8a2V5PkhJRERFTl9ORVRXT1JLPC9rZXk+CgkJCTx0cnVlLz4KCQkJPGtleT5Jc0hvdHNwb3Q8L2tleT4KCQkJPGZhbHNlLz4KCQkJPGtleT5QYXNzd29yZDwva2V5PgoJCQk8c3RyaW5nPmVuZm9yY2UtSEFOREJBTEw8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkRGVzY3JpcHRpb248L2tleT4KCQkJPHN0cmluZz48L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkRGlzcGxheU5hbWU8L2tleT4KCQkJPHN0cmluZz5XaUZpIChTQkMgRGV2aWNlcyk8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkRW5hYmxlZDwva2V5PgoJCQk8dHJ1ZS8+CgkJCTxrZXk+UGF5bG9hZElkZW50aWZpZXI8L2tleT4KCQkJPHN0cmluZz5jb20uYXBwbGUud2lmaS5tYW5hZ2VkLjMzMUFDQTYzLUIxNDEtNDZENS04QjJCLTREMkJBQjVCOEQ5Mjwvc3RyaW5nPgoJCQk8a2V5PlBheWxvYWRPcmdhbml6YXRpb248L2tleT4KCQkJPHN0cmluZz5TdCBCcmlnaWRzIENvbGxlZ2U8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVHlwZTwva2V5PgoJCQk8c3RyaW5nPmNvbS5hcHBsZS53aWZpLm1hbmFnZWQ8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVVVJRDwva2V5PgoJCQk8c3RyaW5nPjMzMUFDQTYzLUIxNDEtNDZENS04QjJCLTREMkJBQjVCOEQ5Mjwvc3RyaW5nPgoJCQk8a2V5PlBheWxvYWRWZXJzaW9uPC9rZXk+CgkJCTxpbnRlZ2VyPjE8L2ludGVnZXI+CgkJCTxrZXk+UHJveHlUeXBlPC9rZXk+CgkJCTxzdHJpbmc+Tm9uZTwvc3RyaW5nPgoJCQk8a2V5PlNTSURfU1RSPC9rZXk+CgkJCTxzdHJpbmc+U0JDIERldmljZXM8L3N0cmluZz4KCQk8L2RpY3Q+Cgk8L2FycmF5PgoJPGtleT5QYXlsb2FkRGVzY3JpcHRpb248L2tleT4KCTxzdHJpbmc+PC9zdHJpbmc+Cgk8a2V5PlBheWxvYWREaXNwbGF5TmFtZTwva2V5PgoJPHN0cmluZz5XaUZpIC0gU0JDIERldmljZXMgKFJldHVybiB0byBTZXJ2aWNlKTwvc3RyaW5nPgoJPGtleT5QYXlsb2FkRW5hYmxlZDwva2V5PgoJPHRydWUvPgoJPGtleT5QYXlsb2FkSWRlbnRpZmllcjwva2V5PgoJPHN0cmluZz5hdS5lZHUud2Euc3RicmlnaWRzLndpZmkucnRzPC9zdHJpbmc+Cgk8a2V5PlBheWxvYWRPcmdhbml6YXRpb248L2tleT4KCTxzdHJpbmc+U3QgQnJpZ2lkcyBDb2xsZWdlPC9zdHJpbmc+Cgk8a2V5PlBheWxvYWRSZW1vdmFsRGlzYWxsb3dlZDwva2V5PgoJPHRydWUvPgoJPGtleT5QYXlsb2FkU2NvcGU8L2tleT4KCTxzdHJpbmc+U3lzdGVtPC9zdHJpbmc+Cgk8a2V5PlBheWxvYWRUeXBlPC9rZXk+Cgk8c3RyaW5nPkNvbmZpZ3VyYXRpb248L3N0cmluZz4KCTxrZXk+UGF5bG9hZFVVSUQ8L2tleT4KCTxzdHJpbmc+NTFFM0UzQzUtREVENy00NzYwLUI2NTEtNUY1QTYwOUI5MkQ5PC9zdHJpbmc+Cgk8a2V5PlBheWxvYWRWZXJzaW9uPC9rZXk+Cgk8aW50ZWdlcj4xPC9pbnRlZ2VyPgo8L2RpY3Q+CjwvcGxpc3Q+Cg=="
				}
		}
}
'

curl -X "PATCH" \
'https://sbcwa.jamfcloud.com/api/v2/mobile-devices/140' \
-H "accept: application/json" \
-H "Authorization: Bearer ${api_token}" \
-H "Content-Type: application/json" \
-d '{
	"updatedExtensionAttributes": [
		{
			"name": "Jamf Setup Role Assigned",
			"type": "STRING",
			"value": [
				""
			],
			"extensionAttributeCollectionAllowed": false
		}
	]
}'