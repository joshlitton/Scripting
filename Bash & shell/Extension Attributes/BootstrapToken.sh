#!/usr/bin/expect
#This will create and escrow the bootstraptoken on the Jamf Pro Server
spawn /usr/bin/profiles install -type bootstraptoken
expect "Enter the admin user name:" 
send "josh.litton\r"
expect "Enter the password for user 'jssadmin':" 
send "meganeRS280\r"
interact