#!/bin/bash



#Make sure OS is 10.13 or later, otherwise exit.  Secure Token was introduced in 10.13
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')
    if [[ $osvers -lt 13 ]]; then
        exit
    fi



#Get list of local os x user accounts
localUsers=$(/usr/bin/dscl /Local/Default -list /Users uid | awk '$2 >= 100 && $0 !~ /^_/ { print $1 }')



#Find users with no secure token
result=$(for i in ${localUsers[@]}
do
/usr/sbin/sysadminctl interactive -secureTokenStatus $i 2>&1 | grep DISABLED | awk '{ print $4,$5,$6,$7,$8,$9,$10,$11 }'
done)



#Send result to Jamf
echo "<result>$result</result>"
