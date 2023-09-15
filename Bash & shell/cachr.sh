#!/bin/zsh
BINNAME="Cachr - OneNote"
BINDESC="Command-line tool to backup and restore OneNote cache. Developed for use during M365/Entra Tenant Migration"
AUTHOR="Josh Litton - Catalytic IT"
VERSION="0.1"
mode="backup"

while test $# -gt 0; do
	case "$1" in
        -h|--help)
			echo "$BINNAME"
            echo "======================"
			echo "Author: $AUTHOR"
            echo " "
            echo "$BINDESC"
			echo "cachr --options"
			echo " "
			echo "options:"
			echo "-h, --help                show this help"
			echo "-v, --version       		show bin version"
			echo "-r, --restore             restore previous cache"
			exit 0
        ;;
		-v|--version)
			echo "VERSION: $VERSION"
			exit 0
		;;
        -r|--restore)
            mode="restore"
		;;
		*)
			break
		;;
	esac
done

# Get the currently logged in user. 
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
# If not user is logged in, exit
if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
	logger "No user logged in at runtime, exiting" 2
    exit 1
fi

# Set pathway variables
backupLocale="/Users/${loggedInUser}/migration/OneNote/"
userDataCache="/Users/${loggedInUser}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Application Support/Microsoft User Data/OneNote/15.0/cache" #

# Unused locations: 
#plist="/Users/${loggedInUser}/Library/Group Containers/UBF8T346G9.Office/OneNote/ShareExtension/Notebooks.plist"
#savedState="/Users/${loggedInUser}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Saved Application State/com.microsoft.onenote.mac.savedState"
#svcCache="/Users/${loggedInUser}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Application Support/Microsoft/Office/16.0/MruServiceCache/597245d8-15f5-47e8-842d-c045fa5e869e_ADAL/OneNote"

# Check if we are processing a backup or restore
if [[ ${mode} == "backup" ]]; then
    /bin/cp -R "$userDataCache" "$backupLocale"
elif [[ ${mode} == "restore" ]]; then
	/bin/cp -R "$userDataCache" "${backupLocale}pre-restore/"
    /usr/bin/su -l "$loggedInUser" -c "cp -R "${backupLocale}/cache/" "$userDataCache""
else
    echo "Unknown mode of operation: ${mode}"
    exit 1
fi


#backupLocale="/Users/${loggedInUser}/migration/OneNote/"
# We only really need this one:
#userDataCache="/Users/${loggedInUser}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Application Support/Microsoft User Data/OneNote/15.0/cache" #
#svcCache="/Users/${loggedInUser}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Application Support/Microsoft/Office/16.0/MruServiceCache/597245d8-15f5-47e8-842d-c045fa5e869e_ADAL/OneNote"

# Restore
#/usr/bin/su -l "$loggedInUser" -c "cp -R "${backupLocale}/cache/" "$userDataCache""

cp -R "$plist" "$backupLocale"
cp -R "$savedState" "$backupLocale"
cp -R "$userDataCache" "$backupLocale"
cp -R "$svcCache" "$backupLocale"
