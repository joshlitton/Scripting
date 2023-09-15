#!/bin/sh
# Username
loggedInUser=$(whoami)
# path to mounts
mountLocale="/Users/$loggedInUser/Library/mnt"
aliasLocale="/Users/$loggedInUser/Documents/"
myMount="$mountLocale/$loggedInUser"
i=0
echo "$mountLocale"

while [ $i -le 5 ]
do
    if [[ -f "$myMount" ]]; then
        # Lets create our Symlinks
        # Get Work
        ln -s -f "$mountLocale/Get_Work" "$aliasLocale"
        sleep 0.5
        # Hand in Work
        ln -s -f "$mountLocale/Hand_In_Work" "$aliasLocale"
        sleep 0.5
        # User Home Folder
        ln -s -f "$mountLocale/$loggedInUser" "$aliasLocale"

        echo "Completed alias creation, exiting script..."
        exit 0
    else
        echo "Mounts dont exist yet, waiting to try again..."
        sleep 3
    fi
    i=$(( i+1 ))
done
exit 1
