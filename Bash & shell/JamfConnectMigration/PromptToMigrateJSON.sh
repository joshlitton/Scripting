#!/bin/zsh

path="/Library/Management/json"
mkdir -p "$path"

tee "$path/swiftDialog_JamfConnectMigration.json" << EOS
{
	"title" : "Authentication Migration",
    "messagefont" : "size=16",
    "message" : "As part of the College's effor to improve security and user experience on MacOS devices, we are updating the software that enables you to log into your Mac with school username and password.
    
    The migration will restart your Mac. Please ensure all of your work has been saved and closed before continuing.
    Do not shut down or close the lid of your Mac during the migration.
    
    ---
    
    *If now is not a suitable time, click defer and you will be prompted again tomorrow. Alternatively, you can manually start the migration any time by running Jamf Connect Migration in Self Service.*",
	"infobox" : "***Deferral will not be allowed after the 17th July***",
    "icon" : "https://ics.services.jamfcloud.com/icon/hash_cfd63778b8e9a5d4b2b22ff2b54ab440b1895d6a24e36b326ff19cb0d9b38901",
    "button1text" : "Migrate Now",
    "button1action" : "jamfselfservice://content?entity=policy&id=65&action=execute",
    "button2" : 1,
    "button2text" : "Defer",
    "infobutton" : 1,
    "infobuttontext" : "Open Self Service",
    "infobuttonaction" : "jamfselfservice://content?entity=policy&id=65&action=view"
}
EOS