#!/bin/bash


####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Ensure computer does not go to sleep while running this script (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Caffeinating this script (PID: $$)"
caffeinate -dimsu -w $$ &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Setup Assistant has completed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

while pgrep -q -x "Setup Assistant"; do
    echo "Setup Assistant is still running; pausing for 2 seconds"
    sleep 2
done

echo "Setup Assistant is no longer running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Dock is running / user is at Desktop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
    echo "Finder & Dock are NOT running; pausing for 1 second"
    sleep 1
done

echo "Finder & Dock are running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
    echo "No user logged-in; exiting."
    exit 1
else
    loggedInUserID=$(id -u "${loggedInUser}")
fi



####################################################################################################
#
# Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version, Jamf Pro Script Parameters and default Exit Code
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.5.1"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
scriptLog="${4:-"/var/tmp/com.jamf.swiftDeploy.log"}"
debugMode="${5:-"true"}"                           # [ true (default) | false ]
welcomeDialog="${6:-"true"}"                       # [ true (default) | false ]
completionActionOption="${7:-"Restart Attended"}"  # [ wait | sleep (with seconds) | Shut Down | Shut Down Attended | Shut Down Confirm | Restart | Restart Attended (default) | Restart Confirm | Log Out | Log Out Attended | Log Out Confirm ]
enablePreDeployment="${8:-"false"}"				   # [ true | false (default) ]
preDeployWaitTime=""							   # How many seconds to wait before running the start-predeploy
reconOptions="-endUsername \"${loggedInUser}\""                                    # Initialize dynamic recon options; built based on user's input at Welcome dialog

exitCode="0"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reflect Debug Mode in `infotext` (i.e., bottom, left-hand corner of each dialog)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]]; then
    scriptVersion="DEBUG MODE | Dialog: v$(dialog --version) • Setup Your Mac: v${scriptVersion}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Dialog path, Command Files, JAMF binary, log files and currently logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/usr/local/bin/dialog"
welcomeCommandFile=$( mktemp /var/tmp/dialogWelcome.XXX )
setupYourMacCommandFile=$( mktemp /var/tmp/dialogSetupYourMac.XXX )
failureCommandFile=$( mktemp /var/tmp/dialogFailure.XXX )
jamfBinary="/usr/local/bin/jamf"
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | cut -d " " -f 1 )



####################################################################################################
#
# Welcome dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeTitle="Welcome to your new Mac, ${loggedInUserFirstname}!"
welcomeMessage="To begin, please enter the required information below, then click **Continue** to start applying settings to your new Mac.  \n\nOnce completed, the **Quit** button will be re-enabled and you'll be prompted to restart your Mac.  \n\nIf you need assistance, please contact the Help Desk: +1 (801) 555-1212."

# Welcome icon set to either light or dark, based on user's Apperance setting (thanks, @mm2270!)
appleInterfaceStyle=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>&1 )
if [[ "${appleInterfaceStyle}" == "Dark" ]]; then
    welcomeIcon="https://cdn-icons-png.flaticon.com/512/9176/9176790.png"
else
    welcomeIcon="https://cdn-icons-png.flaticon.com/512/9176/9176790.png"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" JSON (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeJSON='{
    "title" : "'"${welcomeTitle}"'",
    "message" : "'"${welcomeMessage}"'",
    "icon" : "'"${welcomeIcon}"'",
    "iconsize" : "198.0",
    "button1text" : "Continue",
    "button2text" : "Quit",
    "infotext" : "'"${scriptVersion}"'",
    "blurscreen" : "true",
    "ontop" : "true",
    "titlefont" : "size=26",
    "messagefont" : "size=16",
    "textfield" : [
        {   "title" : "Computer Name",
            "required" : true,
            "prompt" : "Computer Name"
        },
        {   "title" : "Asset Tag",
            "required" : true,
            "prompt" : "See sticker on your Mac, CAT####",
            "regex" : "^CAT[0-9]{4}$",
            "regexerror" : "Please enter your asset tag in the correct format CAT####."
        }
    ],
  "selectitems" : [
        {   "title" : "Department",
            "default" : "Please select your department",
            "values" : [
                "Operations",
                "Service Desk",
                "Managed Services"
            ]
        },
        {   "title" : "Custom Field ",
            "values" : [
                "Option 1",
                "Option 2"
            ]
        }
    ],
    "height" : "400"
}'



####################################################################################################
#
# Setup Your Mac dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" dialog Title, Message, Overlay Icon and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

title="Setting up ${loggedInUserFirstname}'s Mac"
message="Please wait while the following apps are installed …"
overlayicon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )

# Set initial icon based on whether the Mac is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
    icon="SF=laptopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
else
    icon="SF=desktopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogSetupYourMacCMD="$dialogApp \
--title \"$title\" \
--message \"$message\" \
--icon \"$icon\" \
--progress \
--progresstext \"Initializing configuration …\" \
--button1text \"Wait\" \
--button1disabled \
--infotext \"$scriptVersion\" \
--titlefont 'size=28' \
--messagefont 'size=14' \
--height '70%' \
--position 'centre' \
--blurscreen \
--ontop \
--overlayicon \"$overlayicon\" \
--quitkey k \
--commandfile \"$setupYourMacCommandFile\" "


# The fully qualified domain name of the server which hosts your icons, including any required sub-directories
# (P.S. I tried to come up with a longer variable name, but couldn't.)
setupYourMacPolicyArrayIconPrefixUrl="https://ics.services.jamfcloud.com/icon/hash_"

# shellcheck disable=SC1112 # use literal slanted single quotes for typographic reasons

policy_array=('
{
    "steps": [
        {
            "listitem": "Installing Dependencies",
            "icon": "5b1e33ec051ee20465b2bc23bcee4901df0f8307dd2a7eaecb9ee25126b4d793",
            "progresstext": "Installing utilities and dependencies for laptop deployment…",
            "trigger_list": [
                {
                    "trigger": "install-installomator",
                    "path": "/usr/local/Installomator/Installomator.sh"
                },
                {
                    "trigger": "install-dockutil",
                    "path": "/usr/local/bin/dockutil"
                },
                {
                    "trigger": "install-desktoppr",
                    "path": "/usr/local/bin/desktoppr"
                },
                {
                    "trigger": "install-supportapp",
                    "path": "/Applications/Support.app/Contents/Info.plist"
                }
            ]
        },
        {
            "listitem": "Microsoft 365 Apps",
            "icon": "aaec4c3da98529e5491992a3a8458732f27eef5e8f7cdedecc57a4521fa7092a",
            "progresstext": "Installing Microsoft 365 office application suite",
            "trigger_list": [
            	{
                    "trigger": "install-m365",
                    "path": "/Applications/Microsoft Word.app/Contents/Info.plist"
                },
                {
                    "trigger": "install-word",
                    "path": "/Applications/Microsoft Word.app/Contents/Info.plist"
                },
                {
                    "trigger": "install-excel",
                    "path": "/Applications/Microsoft Excel.app/Contents/Info.plist"
                },
                {
                    "trigger": "install-powerpoint",
                    "path": "/Applications/Microsoft PowerPoint.app/Contents/Info.plist"
                },
                {
                    "trigger": "install-outlook",
                    "path": "/Applications/Microsoft Outlook.app/Contents/Info.plist"
                }
            ]
        },
        {
            "listitem": "Microsoft OneDrive",
            "icon": "365e1425d55d51b9b68632025fe2c678052916727a7e8dd011a0c091412e6078",
            "progresstext": "Installing Microsoft OneDrive application to allow automated syncing of files.",
            "trigger_list": [
                {
                    "trigger": "install-onedrive",
                    "path": "/Applications/OneDrive.app/Contents/Info.plist"
                }
            ]
        },
        {
            "listitem": "Company Portal",
            "icon": "2af383e90f870e948ec2d03a5910af1b27fe2b32d7c757848db0fdecfea2ef71",
            "progresstext": "Company Portal is the app that lets you, as an employee of your company, securely access those resources.",
            "trigger_list": [
                {
                    "trigger": "install-mscp",
                    "path": "/Applications/Company Portal.app/Contents/Info.plist"
                }
            ]
        },
        {
            "listitem": "Microsoft Teams",
            "icon": "623505d45ca9c2a1bd26f733306e30cd3fcc1cc0fd59ffc89ee0bfcbfbd0b37e",
            "progresstext": "Microsoft Teams is a hub for teamwork in Office 365. Keep all your team’s chats, meetings and files together in one place.",
            "trigger_list": [
                {
                    "trigger": "install-teams",
                    "path": "/Applications/Microsoft Teams.app/Contents/Info.plist"
                }
            ]
        },
        {
            "listitem": "Acrobat Pro DC",
            "icon": "d5f7f524284ff4ab5671cd5c92ef3938eea192ca4089e0c8b2692f49c5cfe47c",
            "progresstext": "Adobe Acrobat Pro is the complete, cross platform PDF solution. Allowing you to publish, edit and fill in PDF documents.",
            "trigger_list": [
                {
                    "trigger": "install-acrobatpro",
                    "path": "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Info.plist"
                }
            ]
        },
        {
            "listitem": "Setting up your profile",
            "icon": "abac09bcd5cc73858d1624ce187f5a83c80f77fff05ec0e9381e73e2bb84c40c",
            "progresstext": "Running initial setup of your local profile, this will clean up your Dock and set a temporary background",
            "trigger_list": [
                {
                    "trigger": "config-dock",
                    "path": ""
                },
                {
                    "trigger": "config-desktop",
                    "path": ""
                },
                {
                    "trigger": "config-hostname",
                    "path": ""
                }
            ]
        },
        {
            "listitem": "Computer Inventory",
            "icon": "608630cc63690666f21c5d70a7ac08ec14e3117a4c69eb57c7271a75b47a4744",
            "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
            "trigger_list": [
                {
                    "trigger": "recon",
                    "path": ""
                }
            ]
        }
    ]
}
')

#         {
#            "listitem": "FileVault Disk Encryption",
#            "icon": "37d610f8b5c8a57ec0846652627f333d7e1d64fc935a24d616112cf7664c7b91",
#            "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
#            "trigger_list": [
#                {
#                    "trigger": "config-filevault",
#                    "path": "/Library/Preferences/com.apple.fdesetup.plist"
#                }
#            ]
#        },
#
#
#"Installing NoMAD & NoMAD Login,depnotify-NoMAD"
#"Installing 1Password,depNotify1Password"
#"Installing Teamviewer,depNotifyTeamviewer"
#"Installing Firefox,depNotifyFirefox"
#"Installing Chrome,depNotifyChrome"
#"Installing Microsoft Office,depNotifyOffice"
#"Installing Royal TSX,depNotifyRoyal"
#"Installing VPN,depNotifyCheckpoint"
#"Setting Up Printer,depNotifyPrinter"
#"Configuring your Dock,depNotifyDock"

####################################################################################################
#
# Failure dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

failureTitle="Failure Detected"
failureMessage="Placeholder message; update in the 'finalise' function"
failureIcon="SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogFailureCMD="$dialogApp \
--moveable \
--title \"$failureTitle\" \
--message \"$failureMessage\" \
--icon \"$failureIcon\" \
--iconsize 125 \
--width 625 \
--height 400 \
--position topright \
--button1text \"Close\" \
--infotext \"$scriptVersion\" \
--titlefont 'size=22' \
--messagefont 'size=14' \
--overlayicon \"$overlayicon\" \
--commandfile \"$failureCommandFile\" "



#------------------------ With the execption of the `finalise` function, -------------------------#
#------------------------ edits below these line are optional. -----------------------------------#



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dynamically set `button1text` based on the value of `completionActionOption`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${completionActionOption} in

    "Shut Down" )
        button1textCompletionActionOption="Shutting Down …"
        progressTextCompletionAction="shut down and "
        ;;

    "Shut Down "* )
        button1textCompletionActionOption="Shut Down"
        progressTextCompletionAction="shut down and "
        ;;

    "Restart" )
        button1textCompletionActionOption="Restarting …"
        progressTextCompletionAction="restart and "
        ;;

    "Restart "* )
        button1textCompletionActionOption="Restart"
        progressTextCompletionAction="restart and "
        ;;

    "Log Out" )
        button1textCompletionActionOption="Logging Out …"
        progressTextCompletionAction="log out and "
        ;;

    "Log Out "* )
        button1textCompletionActionOption="Log Out"
        progressTextCompletionAction="log out and "
        ;;

    "Sleep"* )
        button1textCompletionActionOption="Close"
        progressTextCompletionAction=""
        ;;

    "Quit" )
        button1textCompletionActionOption="Quit"
        progressTextCompletionAction=""
        ;;

    * )
        button1textCompletionActionOption="Close"
        progressTextCompletionAction=""
        ;;

esac



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# shellcheck disable=SC2145
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {

    updateScriptLog "Run \"$@\" as \"$loggedInUserID\" … "
    launchctl asuser "$loggedInUserID" sudo -u "$loggedInUser" "$@"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        updateScriptLog "Dialog not found. Installing..."

        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

        # Download the installer package
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            updateScriptLog "swiftDialog version $(dialog --version) installed; proceeding..."

        else

            # Display a so-called "simple" dialog if Team ID fails to validate
            runAsUser osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Setup Your Mac: Error" buttons {"Close"} with icon caution'
            completionActionOption="Quit"
            exitCode="1"
            quitScript

        fi

        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"

    else

        updateScriptLog "swiftDialog version $(dialog --version) found; proceeding..."

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Welcome" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateWelcome(){
    updateScriptLog "WELCOME DIALOG: $1"
    echo "$1" >> "$welcomeCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Setup Your Mac" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateSetupYourMac() {
    updateScriptLog "SETUP YOUR MAC DIALOG: $1"
    echo "$1" >> "$setupYourMacCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Failure" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateFailure(){
    updateScriptLog "FAILURE DIALOG: $1"
    echo "$1" >> "$failureCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Finalise User Experience
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function finalise(){

    if [[ "${jamfProPolicyTriggerFailure}" == "failed" ]]; then

        killProcess "caffeinate"
        updateScriptLog "Jamf Pro Policy Name Failures: ${jamfProPolicyPolicyNameFailures}"
        dialogUpdateSetupYourMac "title: Sorry ${loggedInUserFirstname}, something went sideways"
        dialogUpdateSetupYourMac "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        dialogUpdateSetupYourMac "progresstext: Failures detected. Please click Continue for troubleshooting information."
        dialogUpdateSetupYourMac "button1text: Continue …"
        dialogUpdateSetupYourMac "button1: enable"
        dialogUpdateSetupYourMac "progress: complete"

        # Wait for user-acknowledgment due to detected failure
        wait

        dialogUpdateSetupYourMac "quit:"
        eval "${dialogFailureCMD}" & sleep 0.3

        dialogUpdateFailure "message: A failure has been detected, ${loggedInUserFirstname}.  \n\nPlease complete the following steps:\n1. Reboot and login to your Mac  \n2. Login to Self Service  \n3. Re-run any failed policy listed below  \n\nThe following failed to install:  \n${jamfProPolicyPolicyNameFailures}  \n\n\n\nIf you need assistance, please contact the Help Desk,  \n+1 (801) 555-1212, and mention [KB86753099](https://servicenow.company.com/support?id=kb_article_view&sysparm_article=KB86753099#Failures). "
        dialogUpdateFailure "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        dialogUpdateFailure "button1text: ${button1textCompletionActionOption}"

        # Wait for user-acknowledgment due to detected failure
        wait

        dialogUpdateFailure "quit:"
        quitScript "1"

    else

        dialogUpdateSetupYourMac "title: ${loggedInUserFirstname}'s Mac is ready!"
        dialogUpdateSetupYourMac "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        dialogUpdateSetupYourMac "progresstext: Complete! Please ${progressTextCompletionAction}enjoy your new Mac, ${loggedInUserFirstname}!"
        dialogUpdateSetupYourMac "progress: complete"
        dialogUpdateSetupYourMac "button1text: ${button1textCompletionActionOption}"
        dialogUpdateSetupYourMac "button1: enable"

        # If either "wait" or "sleep" has been specified for `completionActionOption`, honor that behavior
        if [[ "${completionActionOption}" == "wait" ]] || [[ "${completionActionOption}" == "[Ss]leep"* ]]; then
            updateScriptLog "Honoring ${completionActionOption} behavior …"
            eval "${completionActionOption}" "${dialogSetupYourMacProcessID}"
        fi

        quitScript "0"

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value() {
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env).$2"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript for the Welcome dialog (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value_welcomeDialog () {
    for var in "${@:2}"; do jsonkey="${jsonkey}['${var}']"; done
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env)$jsonkey"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Jamf Pro Policy Custom Events (thanks, @smithjw)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function run_jamf_trigger() {

    trigger="$1"

    if [[ "${debugMode}" == "true" ]]; then

        updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: TRIGGER: $jamfBinary policy -event $trigger"
        if [[ "$trigger" == "recon" ]]; then
            updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: RECON: $jamfBinary recon ${reconOptions}"
        fi
        sleep 1

    elif [[ "$trigger" == "recon" ]]; then

        dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Updating …, "
        updateScriptLog "SETUP YOUR MAC DIALOG: Updating computer inventory with the following reconOptions: \"${reconOptions}\" …"
        eval "${jamfBinary} recon ${reconOptions}"

    else

        updateScriptLog "SETUP YOUR MAC DIALOG: RUNNING: $jamfBinary policy -event $trigger"
        "$jamfBinary" policy -event "$trigger"

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        updateScriptLog "Attempting to terminate the '$process' process …"
        updateScriptLog "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            updateScriptLog "ERROR: '$process' could not be terminated."
        fi
    else
        updateScriptLog "The '$process' process isn't running."
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Completion Action (i.e., Wait, Sleep, Logout, Restart or Shutdown)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function completionAction() {

    if [[ "${debugMode}" == "true" ]]; then

        # If Debug Mode is enabled, ignore specified `completionActionOption`, display simple dialog box and exit
        runAsUser osascript -e 'display dialog "Setup Your Mac is operating in Debug Mode.\r\r• completionActionOption == '"'${completionActionOption}'"'\r\r" with title "Setup Your Mac: Debug Mode" buttons {"Close"} with icon note'
        exitCode="0"

    else

        shopt -s nocasematch

        case ${completionActionOption} in

            "Shut Down" )
                updateScriptLog "Shut Down sans user interaction"
                killProcess "Self Service"
                # runAsUser osascript -e 'tell app "System Events" to shut down'
                sleep 5 && runAsUser osascript -e 'tell app "System Events" to shut down' &
                # shutdown -h +1 &
                ;;

            "Shut Down Attended" )
                updateScriptLog "Shut Down, requiring user-interaction"
                killProcess "Self Service"
                wait
                # runAsUser osascript -e 'tell app "System Events" to shut down'
                sleep 5 && runAsUser osascript -e 'tell app "System Events" to shut down' &
                # shutdown -h +1 &
                ;;

            "Shut Down Confirm" )
                updateScriptLog "Shut down, only after macOS time-out or user confirmation"
                runAsUser osascript -e 'tell app "loginwindow" to «event aevtrsdn»'
                ;;

            "Restart" )
                updateScriptLog "Restart sans user interaction"
                killProcess "Self Service"
                # runAsUser osascript -e 'tell app "System Events" to restart'
                sleep 5 && runAsUser osascript -e 'tell app "System Events" to restart' &
                # shutdown -r +1 &
                ;;

            "Restart Attended" )
                updateScriptLog "Restart, requiring user-interaction"
                killProcess "Self Service"
                wait
                # runAsUser osascript -e 'tell app "System Events" to restart'
                sleep 5 && runAsUser osascript -e 'tell app "System Events" to restart' &
                # shutdown -r +1 &
                ;;

            "Restart Confirm" )
                updateScriptLog "Restart, only after macOS time-out or user confirmation"
                runAsUser osascript -e 'tell app "loginwindow" to «event aevtrrst»'
                ;;

            "Log Out" )
                updateScriptLog "Log out sans user interaction"
                killProcess "Self Service"
                # runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»'
                sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»' &
                # launchctl bootout user/"${loggedInUserID}"
                ;;

            "Log Out Attended" )
                updateScriptLog "Log out sans user interaction"
                killProcess "Self Service"
                wait
                # runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»'
                sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»' &
                # launchctl bootout user/"${loggedInUserID}"
                ;;

            "Log Out Confirm" )
                updateScriptLog "Log out, only after macOS time-out or user confirmation"
                runAsUser osascript -e 'tell app "System Events" to log out'
                ;;

            "Sleep"* )
                sleepDuration=$( awk '{print $NF}' <<< "${1}" )
                updateScriptLog "Sleeping for ${sleepDuration} seconds …"
                sleep "${sleepDuration}"
                killProcess "Dialog"
                updateScriptLog "Goodnight!"
                ;;

            "Quit" )
                updateScriptLog "Quitting script"
                exitCode="0"
                ;;

            * )
                updateScriptLog "Using the default of 'wait'"
                wait
                ;;

        esac

        shopt -u nocasematch

    fi

    exit "${exitCode}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    updateScriptLog "Exiting …"

    # Stop `caffeinate` process
    updateScriptLog "De-caffeinate …"
    killProcess "caffeinate"

    # Remove welcomeCommandFile
    if [[ -e ${welcomeCommandFile} ]]; then
        updateScriptLog "Removing ${welcomeCommandFile} …"
        rm "${welcomeCommandFile}"
    fi

    # Remove setupYourMacCommandFile
    if [[ -e ${setupYourMacCommandFile} ]]; then
        updateScriptLog "Removing ${setupYourMacCommandFile} …"
        rm "${setupYourMacCommandFile}"
    fi

    # Remove failureCommandFile
    if [[ -e ${failureCommandFile} ]]; then
        updateScriptLog "Removing ${failureCommandFile} …"
        rm "${failureCommandFile}"
    fi

    # Remove any default dialog file
    if [[ -e /var/tmp/dialog.log ]]; then
        updateScriptLog "Removing default dialog file …"
        rm /var/tmp/dialog.log
    fi

    # Check for user clicking "Quit" at Welcome dialog
    if [[ "${welcomeReturnCode}" == "2" ]]; then
        exitCode="1"
        exit "${exitCode}"
    else
        updateScriptLog "Executing Completion Action Option: '${completionActionOption}' …"
        completionAction "${completionActionOption}"
    fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]]; then
    updateScriptLog "\n\n###\n# ${scriptVersion}\n###\n"
else
    updateScriptLog "\n\n###\n# Setup Your Mac (${scriptVersion})\n###\n"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate swiftDialog is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# If Debug Mode is enabled, replace `blurscreen` with `movable`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]]; then
    welcomeJSON=${welcomeJSON//blurscreen/moveable}
    dialogSetupYourMacCMD=${dialogSetupYourMacCMD//blurscreen/moveable}
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Write Welcome JSON to disk
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "$welcomeJSON" > "$welcomeCommandFile"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Welcome dialog and capture user's input
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${welcomeDialog}" == "true" ]]; then

    welcomeResults=$( ${dialogApp} --jsonfile "$welcomeCommandFile" --json )
    if [[ -z "${welcomeResults}" ]]; then
        welcomeReturnCode="2"
    else
        welcomeReturnCode="0"
    fi

    case "${welcomeReturnCode}" in

        0)  # Process exit code 0 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} entered information and clicked Continue"

            ###
            # Extract the various values from the welcomeResults JSON
            ###

            comment=$(get_json_value_welcomeDialog "$welcomeResults" "Comment")
            computerName=$(get_json_value_welcomeDialog "$welcomeResults" "Computer Name")
            # We still want user assignment, but dont want to use logged in username
            userName=$(echo "${loggedInUser}")
            #userName=$(get_json_value_welcomeDialog "$welcomeResults" "User Name")
            assetTag=$(get_json_value_welcomeDialog "$welcomeResults" "Asset Tag")
            department=$(get_json_value_welcomeDialog "$welcomeResults" "Department" "selectedValue")
            selectB=$(get_json_value_welcomeDialog "$welcomeResults" "Select B" "selectedValue")
            selectC=$(get_json_value_welcomeDialog "$welcomeResults" "Select C" "selectedValue")



            ###
            # Output the various values from the welcomeResults JSON to the log file
            ###

            updateScriptLog "WELCOME DIALOG: • Comment: $comment"
            updateScriptLog "WELCOME DIALOG: • Computer Name: $computerName"
            updateScriptLog "WELCOME DIALOG: • User Name: $userName"
            updateScriptLog "WELCOME DIALOG: • Asset Tag: $assetTag"
            updateScriptLog "WELCOME DIALOG: • Department: $department"
            updateScriptLog "WELCOME DIALOG: • Select B: $selectB"
            updateScriptLog "WELCOME DIALOG: • Select C: $selectC"



            ###
            # Evaluate Various User Input
            ###

            # Computer Name
            if [[ -n "${computerName}" ]]; then

                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                updateScriptLog "WELCOME DIALOG: Set Computer Name …"
                currentComputerName=$( scutil --get ComputerName )
                currentLocalHostName=$( scutil --get LocalHostName )

                # Sets LocalHostName to a maximum of 15 characters, comprised of first eight characters of the computer's
                # serial number and the last six characters of the client's MAC address
                firstEightSerialNumber=$( system_profiler SPHardwareDataType | awk '/Serial\ Number\ \(system\)/ {print $NF}' | cut -c 1-8 )
                lastSixMAC=$( ifconfig en0 | awk '/ether/ {print $2}' | sed 's/://g' | cut -c 7-12 )
                newLocalHostName=${firstEightSerialNumber}-${lastSixMAC}

                if [[ "${debugMode}" == "true" ]]; then

                    updateScriptLog "WELCOME DIALOG: DEBUG MODE: Renamed computer from: \"${currentComputerName}\" to \"${computerName}\" "
                    updateScriptLog "WELCOME DIALOG: DEBUG MODE: Renamed LocalHostName from: \"${currentLocalHostName}\" to \"${newLocalHostName}\" "

                else

                    # Set the Computer Name to the user-entered value
                    scutil --set ComputerName "${computerName}"

                    # Set the LocalHostName to `newLocalHostName`
                    scutil --set LocalHostName "${computerName}"
                    #scutil --set LocalHostName "${newLocalHostName}"

                    # Delay required to reflect change …
                    # … side-effect is a delay in the "Setup Your Mac" dialog appearing
                    sleep 5
                    updateScriptLog "WELCOME DIALOG: Renamed computer from: \"${currentComputerName}\" to \"$( scutil --get ComputerName )\" "
                    updateScriptLog "WELCOME DIALOG: Renamed LocalHostName from: \"${currentLocalHostName}\" to \"$( scutil --get LocalHostName )\" "

                fi

            else

                updateScriptLog "WELCOME DIALOG: ${loggedInUser} did NOT specify a new computer name"
                updateScriptLog "WELCOME DIALOG: • Current Computer Name: \"$( scutil --get ComputerName )\" "
                updateScriptLog "WELCOME DIALOG: • Current Local Host Name: \"$( scutil --get LocalHostName )\" "

            fi

            # User Name
            if [[ -n "${userName}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-endUsername \"${userName}\" "
            fi

            # Asset Tag
            if [[ -n "${assetTag}" ]]; then
                reconOptions+="-assetTag \"${assetTag}\" "
            fi

            # Department
            if [[ -n "${department}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-department \"${department}\" "
            fi

            # Output `recon` options to log
            updateScriptLog "WELCOME DIALOG: reconOptions: ${reconOptions}"

            ###
            # Display "Setup Your Mac" dialog (and capture Process ID)
            ###

            eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
            dialogSetupYourMacProcessID=$!
            ;;

        2)  # Process exit code 2 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked Quit at Welcome dialog"
            completionActionOption="Quit"
            quitScript "1"
            ;;

        3)  # Process exit code 3 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked infobutton"
            osascript -e "set Volume 3"
            afplay /System/Library/Sounds/Glass.aiff
            ;;

        4)  # Process exit code 4 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} allowed timer to expire"
            quitScript "1"
            ;;

        *)  # Catch all processing
            updateScriptLog "WELCOME DIALOG: Something else happened; Exit code: ${welcomeReturnCode}"
            quitScript "1"
            ;;

    esac

else

    ###
    # Display "Setup Your Mac" dialog (and capture Process ID)
    ###

    eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
    dialogSetupYourMacProcessID=$!

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Iterate through policy_array JSON to construct the list for swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialog_step_length=$(get_json_value "${policy_array[*]}" "steps.length")
for (( i=0; i<dialog_step_length; i++ )); do
    listitem=$(get_json_value "${policy_array[*]}" "steps[$i].listitem")
    list_item_array+=("$listitem")
    icon=$(get_json_value "${policy_array[*]}" "steps[$i].icon")
    icon_url_array+=("$icon")
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set progress_total to the number of steps in policy_array
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

progress_total=$(get_json_value "${policy_array[*]}" "steps.length")
updateScriptLog "SETUP YOUR MAC DIALOG: progress_total=$progress_total"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The ${array_name[*]/%/,} expansion will combine all items within the array adding a "," character at the end
# To add a character to the start, use "/#/" instead of the "/%/"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

list_item_string=${list_item_array[*]/%/,}
dialogUpdateSetupYourMac "list: ${list_item_string%?}"
for (( i=0; i<dialog_step_length; i++ )); do
    dialogUpdateSetupYourMac "listitem: index: $i, icon: ${setupYourMacPolicyArrayIconPrefixUrl}${icon_url_array[$i]}, status: pending, statustext: Pending …"
done
dialogUpdateSetupYourMac "list: show"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set initial progress bar
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

progress_index=0
dialogUpdateSetupYourMac "progress: $progress_index"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Close Welcome dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogUpdateWelcome "quit:"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# This for loop will iterate over each distinct step in the policy_array array
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

for (( i=0; i<dialog_step_length; i++ )); do

    # Increment the progress bar
    dialogUpdateSetupYourMac "progress: $(( i * ( 100 / progress_total ) ))"

    # Creating initial variables
    listitem=$(get_json_value "${policy_array[*]}" "steps[$i].listitem")
    icon=$(get_json_value "${policy_array[*]}" "steps[$i].icon")
    progresstext=$(get_json_value "${policy_array[*]}" "steps[$i].progresstext")

    trigger_list_length=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list.length")

    # If there's a value in the variable, update running swiftDialog
    if [[ -n "$listitem" ]]; then dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Installing …, "; fi
    if [[ -n "$icon" ]]; then dialogUpdateSetupYourMac "icon: ${setupYourMacPolicyArrayIconPrefixUrl}${icon}"; fi
    if [[ -n "$progresstext" ]]; then dialogUpdateSetupYourMac "progresstext: $progresstext"; fi
    if [[ -n "$trigger_list_length" ]]; then
        for (( j=0; j<trigger_list_length; j++ )); do

            # Setting variables within the trigger_list
            trigger=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list[$j].trigger")
            path=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list[$j].path")

            # If the path variable has a value, check if that path exists on disk
            if [[ -f "$path" ]]; then
                updateScriptLog "SETUP YOUR MAC DIALOG: INFO: $path exists, moving on"
                if [[ "${debugMode}" == "true" ]]; then sleep 0.5; fi
            else
                run_jamf_trigger "$trigger"
            fi
        done
    fi

    # Validate the expected path exists
    updateScriptLog "SETUP YOUR MAC DIALOG: Testing for \"$path\" …"
    if [[ -f "$path" ]] || [[ -z "$path" ]]; then
        dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
        if [[ "$trigger" == "recon" ]]; then
            dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Updated"
        fi
    else
        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
        jamfProPolicyTriggerFailure="failed"
        exitCode="1"
        jamfProPolicyPolicyNameFailures+="• $listitem  \n"
    fi

done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete processing and enable the "Done" button
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

finalise