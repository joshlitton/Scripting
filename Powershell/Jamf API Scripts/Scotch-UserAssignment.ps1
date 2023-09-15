#These commands weren't functional with Powershell ISE
#$myPath = split-path -path $MyInvocation.MyCommand.Definition -parent
#Set-Location $myPath
try {
    . "C:\Scripts\JamfPro\UserAssignment\logger.ps1"
}
catch {
    Write-Host "Error loading supporting PowerShell Scripts" -BackgroundColor RED
    exit
}

#############
# Variables #
#############
$maxAssignments = 1 # If more than X users assigned in WHD, show warning
$LogSummary = 1
#############
# Constants #
#############
$creds = "anNzYXBpc2NvdGNod2hkOnlvbmRlci1FUVVBVEUzbmV3" # JSS API - Web Help Desk
# Define our empty arrays
$Computers =@() # Store our Computer objects
$EmailCount = @() # Store IDs that don't have a User assigned in Jamf


# Create a class of object to store our records
class Computer {
    [int]$ID
    [string]$Serial
    [string]$Email
    [int]$WHD_ClientID
    [int]$WHD_AssetID;
}


# SQL Details
$DBServer = "sql01-service.plcscotch.wa.edu.au"
$Database = "whd-service"

# Headers to Generate Bearer Token
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $creds")
$headers.Add("Content-Type", "application/json")
$headers.Add("Cookie", "APBALANCEID=aws.apse2-std-pelican1-tc-3")

Log "INFO", "Registering Bearer Token for script run"
$token = Invoke-RestMethod 'https://jss.plcscotch.wa.edu.au:8443/api/v1/auth/token' -Method 'POST' -Headers $headers

Log "INFO", "Updating Authorization to use Token"
# Update Authorization Header to use token. 
$headers.Authorization = "Bearer $($token.token)"
Start-Sleep -Seconds 1

# Get ALL Computers in Jamf Pro
Log "INFO", "Getting a list of computers in Jamf Pro"
$response = Invoke-RestMethod 'https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory?section=GENERAL&section=HARDWARE&page=0&page-size=1000' -Method 'GET' -Headers $headers

# Calculate the pages required (roud down because we start at 0)
$pages = [math]::Floor($response.totalCount / 1000)


# Iterate through all pages
foreach($i in 0..$pages){
        #Log "INFO", "Collecting page $i of $pages"
        $response = Invoke-RestMethod "https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory?section=GENERAL&section=HARDWARE&section=USER_AND_LOCATION&page=$i&page-size=1000" -Method 'GET' -Headers $headers

        # Loop through each computer on the page
        foreach ($device in $response.results){
            # Only grab devices in Scotch site. 
            if ($device.general.site.name -eq "Scotch"){
                if ($device.hardware.serialNumber -eq $null ) {
                    Log "WARN", "Device ID $($device.id) has no Serial Number in Jamf"
                } elseif ($device.userAndLocation.email -eq $null) {
                    #Log "WARN", "Device ID $($device.id) has no Email Address in Jamf!"
                    $EmailCount += $device.id
                } else {
                    $obj = [Computer]::new()
                    $obj.ID = $device.id
                    $obj.Serial = $device.hardware.serialNumber
                    $obj.Email = $device.userAndLocation.email
                    $Computers += $obj
                }
            } else {
                #LOG "INFO", "$($computer.hardware.serialNumber) is not in Scotch site."
            }
        }
}


### Loop through our array of custom objects
### 1. Query the ASSET table to get ASSET_ID based on Serial # from Jamf
### 2. Query the Client table to get CLIENT_ID based on email address from Jamf
### 3. Confirm devices have ASSET_ID and CLIENT_ID, if so, 

Log "INFO", "Checking assignments on $($computers.Count) computers..."

foreach ($Computer in $Computers){
    #1.
    $q = "SELECT * FROM whd.Asset WHERE SERIAL_NUMBER='$($Computer.Serial)' AND isnull(DELETED, 0) = 0"
    $return = Invoke-sqlcmd -serverinstance $DBServer -database $Database -query $q -ErrorAction Stop
    if ($return.ASSET_ID.Count -gt 1){
        LOG "WARN", "Duplicate asset records for $($computer.serial): $($return.ASSET_ID)"
    } else {
        # Add our ASSET ID to the object
        $computer.WHD_AssetID = $return.ASSET_ID
    }


    #2.
    $q = "SELECT * FROM whd.Client WHERE EMAIL='$($Computer.Email)' AND isnull(DELETED, 0) = 0 AND isnull(INACTIVE, 0) = 0 AND LDAP_CONNECTION_ID is not null"
    $return = Invoke-sqlcmd -serverinstance $DBServer -database $Database -query $q -ErrorAction Stop
    if ($return.CLIENT_ID.Count -gt 1){
        Log "WARN", "Duplicate records for $($computer.email): $($return.CLIENT_ID)"
    } elseif ($return.CLIENT_ID -eq $null) {
        Log "WARN", "No acive account in Web Help Desk found for: $($computer.email)."
    } else {
        #Write-Host $return.CLIENT_ID $Computer.Email
        $Computer.WHD_ClientID = $return.CLIENT_ID
    }

    # TBD - IF EITHER FIELD BLANK, LOG AND SKIP
    #3. 
    if ($Computer.WHD_AssetID -eq $null) {
        Log "ERROR", "AssetID not found in WHD for: $($Computer.Serial)"
    } elseif ($Computer.WHD_ClientID -eq $null) {
        Log "ERROR", "ClientID not found in WHD for: $($Computer.Email)"
    } else {
        $q = "SELECT * from whd.Asset_Client WHERE ASSET_ID='$($Computer.WHD_ASSETID)'"
        $return = Invoke-sqlcmd -serverinstance $DBServer -database $Database -query $q -ErrorAction Stop
        # Check if the Client ID in WHD is the same as what we found in Jamf
        if ($return.CLIENT_ID -eq $Computer.WHD_ClientID) {
            #Write-Host "Assignment already matches, skipping"
        } else {
            $q = "INSERT INTO whd.Asset_Client (ASSET_ID, CLIENT_ID) values ($Computer.WHD_ASSETID, $Computer.WHD_CLIENTID)"
            LOG "INFO", "Assignment for $($computer.serial) does not match, Updating to $($Computer.email)"
            try {
            ###################################################
            # Comment out line below to stop Database writing #
            ###################################################
            #Invoke-sqlcmd -serverinstance $DBServer -database $Database -query $q -ErrorAction Stop
            
            } catch {LOG "ERROR", "Failed to insert User Assignment into database. $($computer.Serial), $($computer.email)"} 
            
        }
        # Check the amount of assignments after updating
        $q = "SELECT * from whd.Asset_Client WHERE ASSET_ID='$($Computer.WHD_ASSETID)'"
        $return = Invoke-sqlcmd -serverinstance $DBServer -database $Database -query $q -ErrorAction Stop
        if ($return.CLIENT_ID.count -gt $maxAssignments){
            LOG "WARN", "$($Computer.Serial) is assigned to $($return.CLIENT_ID.count) users."
        }
    }
}
Log "WARN", "$($EmailCount.Count) devices do not have an email address assigned"
if ($LogSummary -eq 1){
    Log "INFO", "$EmailCount"
}