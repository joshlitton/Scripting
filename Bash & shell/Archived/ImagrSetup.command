#!/bin/bash

#Name of USB
VOLNAME=WinthropDeploy
#Pathway to config property list
URL="file:///Volumes/WinthropDeploy/imagr/imagr_config.plist"


###################
#Do Not Edit Below#
###################
PLIST=/Volumes/$VOLNAME/var/root/Library/Preferences/com.grahamgilbert.Imagr.plist
KEY=serverurl
{
defaults write $PLIST $KEY $URL &&
echo "Script Completed"
} || {
echo "Failed"
}
exit 0