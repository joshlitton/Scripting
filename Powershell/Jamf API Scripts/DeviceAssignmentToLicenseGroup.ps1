#These commands weren't functional with Powershell ISE
#$myPath = split-path -path $MyInvocation.MyCommand.Definition -parent
#Set-Location $myPath
try {
    . "C:\Scripts\JamfPro\UserAssignmentDevices\logger.ps1"
}
catch {
    Write-Host "Error loading supporting PowerShell Scripts" -BackgroundColor RED
    exit
}

#############
# Variables #
#############
$maxAssignments = 1 # If more than X users assigned in WHD, show warning
$DEBUG = 1 # 1 = Enabled
#############
# Constants #
#############
$base64AuthInfo = "anNzYXBpdGVzdDpEVUZGRVItc2tpbGxldC1ub25jZQ==" # JSS API Testing
$jss = "https://jss.plcscotch.wa.edu.au:8443"
# A5 Licensed AD Group 
$ADGroupA5License = "sct_o365_grp_License_A5Faculty_deviceowners"
# Used to refine the search base for matching emails of identified users to update with ADUser objects. Required to exclude Staff that are also parents (they have a matching email on their parent account)
$StaffOU = "OU=Staff,OU=Users,OU=Scotch,OU=PLCScotch,DC=plcscotch,DC=wa,DC=edu,DC=au"
#Timeout timer - used for loops to check AD membership. This can take a while to report changes
$Timeout = 30
# Define our empty arrays
$JamfStaffWithDevices =@()
$ADStaffWithA5 =@()

function main() {
    
	$JamfStaffWithDevices = getJamfGroup #Lets list out every staff member that has a device
    $JamfStaffWithDevices | Export-CSV -notypeinformation ./StaffWithDevices-LastRun.csv
    #$JamfStaffWithDevices = Import-Csv -Path "C:\scripts\JamfPro\DeviceAssignmentToLicenseGroup\StaffWithDevices-LastRun.csv" # This can be used for rapid testing witht he latest data extracted from the last run-time
    $ADStaffWithA5 = getADGroup $ADGroupA5License #Get a list of users that are members of the A5 license group in AD

    $UsersToAdd = getArrayComparison -Array1 $JamfStaffWithDevices -Array2 $ADStaffWithA5 -Field "EmailAddress" -nomatch
    $UsersToRemove = getArrayComparison -Array1 $ADStaffWithA5 -Array2 $JamfStaffWithDevices -Field "EmailAddress" -nomatch

    # Remove Users without a device or computer in Jamf
    foreach ($email in $UsersToRemove) {
        $user = Get-ADUser -SearchBase "$StaffOU" -Filter {EmailAddress -eq $email} -Properties DisplayName, EmailAddress, SamAccountName
        if ($user) {
            try {
                if ($DEBUG -eq 1){Log "DEBUG", "Removing $($user.DisplayName) from A5 Licensing Group"}
                # Remove the user from the group
                Remove-ADPrincipalGroupMembership -Identity "$($user.SamAccountName)" -MemberOf $ADGroupA5License

            } catch {Log "ERROR", "Unable to remove $($user.DisplayName) from A5 License Group"}

            $groups = $(Get-ADPrincipalGroupMembership -Identity "$($user.SamAccountName)").Name
            if ($DEBUG -eq 1) {Log "DEBUG", "$groups"}
            $i = 0
            # We need to give AD time to reflect the changes
            while ($Timeout -gt $i -and ($ADGroupA5License -in $groups)) {
                $i += 1
                if ($DEBUG = 1){Log "DEBUG", "Loop $i of checking user group membership. Timeout at $Timeout"}
                Start-Sleep 1
                $groups = $(Get-ADPrincipalGroupMembership -Identity "$($user.SamAccountName)").Name
            }
            # Checking for membership to apply ext attribute, we dont want ext. attribute without membership or users may become unlicensed
            # This could be moved to it's own loop that iterates through the AD group and confirms all users have A5 attribute assigned. 
            if ($ADGroupA5License -notin $groups) {
                Log "INFO", "$($user.SamAccountName) successfully removed from group."
                try {Set-ExtensionAttribute -Identity "$($user.SamAccountName)" -Attribute "ExtensionAttribute15" -Clear} catch {Log "WARN", "Unable to clear ExtensionAttribute15 for $($user.SamAccountName)"}
            }
        } else {
            log "WARN", "No AD account with email: $email was found in $StaffOU"
        }
    }

    # Add users with a device or computer in Jamf
    foreach ($email in $UsersToAdd) {
        $user = Get-ADUser -SearchBase "$StaffOU" -Filter {EmailAddress -eq $email} -Properties DisplayName, EmailAddress, SamAccountName
        if ($user) {
            try {
                Add-ADPrincipalGroupMembership -Identity "$($user.SamAccountName)" -MemberOf $ADGroupA5License
                Log "DEBUG", "Adding $($user.DisplayName) to A5 Licensing Group"
            } catch {Log "ERROR", "Unable to add $($user.DisplayName) to A5 License Group"}
            $groups = $(Get-ADPrincipalGroupMembership -Identity "$($user.SamAccountName)").Name
            if ($DEBUG = 1){Log "DEBUG", "$groups"}
            $i = 0
            # We need to give AD time to reflect the changes
            while ($Timeout -gt $i -and ($ADGroupA5License -notin $groups)) {
                $i += 1
                if ($DEBUG = 1){Log "DEBUG", "Loop $i of checking user group membership. Timeout at $Timeout"}
                Start-Sleep 1
                $groups = $(Get-ADPrincipalGroupMembership -Identity "$($user.SamAccountName)").Name
            }
            # Checking for membership to apply ext attribute, we dont want ext. attribute without membership or users may become unlicensed
            # This could be moved to it's own loop that iterates through the AD group and confirms all users have A5 attribute assigned. 
            if ($ADGroupA5License -in $groups) {
                Log "INFO", "$($user.SamAccountName) successfully added to group."
                try {Set-ExtensionAttribute -Identity "$($user.SamAccountName)" -Attribute "ExtensionAttribute15" -Value "A5"} catch {Log "WARN", "Unable to update ExtensionAttribute15 for $($user.SamAccountName)"}
            }
        } else {
            log "WARN", "No AD account with email: $email was found in $StaffOU"
        }
    }

    ###TODO
    # Run AD Connect Sync remotely? 

    Log "INFO", "Script finished running"
}

##         ##
# Functions #
##         ##
function getJamfGroup() {
    Log "INFO", "Storing Bearer Token for script use"
    $token = getBearerToken

    $ScotchStaff = getUsersFromGroup $token "24"
	$objArray=@()
    foreach ($StaffMember in $ScotchStaff) {
        $JamfUser = getUserDevices $token $StaffMember.id
        if (($JamfUser.links.mobile_devices) -Or ($JamfUser.links.computers)) {
            $objArray += [PSCustomObject]@{
				JamfID = $JamfUser.id
				FullName = $JamfUser.full_name
				EmailAddress = $JamfUser.email
			}
        } else {
            #User in Jamf does not have a device assigned
            #maybe something here to check if they are in the AD group and remove them if required.
        }
    }
	
	return $objArray
}

function getBearerToken() {
    Log "INFO", "Registering Bearer Token for script run"
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }
    
    $Parameters = @{
        Method      = "POST"
        Uri         = "$jss/api/v1/auth/token"
        Headers     = $Header
    }
    
    $authToken = Invoke-RestMethod @Parameters

    $token = $authToken.token

    return $token
}

function getUsersFromGroup([string]$jamftoken, [string]$groupid) {
    $Header = @{
        "authorization" = "Bearer $jamftoken"
    }
    
    $Parameters = @{
        Method      = "GET"
        Uri         = "$jss/JSSResource/usergroups/id/$groupid"
        Headers     = $Header
        ContentType = "application/json"
    }
    
    $Users = Invoke-RestMethod @Parameters

    return $Users.user_group.users.user
}

function getUserDevices([string]$jamftoken, [string]$userid) {
    $Header = @{
        "authorization" = "Bearer $jamftoken"
    }
    
    $Parameters = @{
        Method      = "GET"
        Uri         = "$jss/JSSResource/users/id/$userid"
        Headers     = $Header
        ContentType = "application/json"
    }
    
    $User = Invoke-RestMethod @Parameters

    return $User.user
}

function getADGroup([string]$adgroup) {
    $members = $(Get-ADGroupMember -Identity $adgroup | Select-Object -Property SamAccountName )
    $memberArray=@()
    foreach ($member in $members) {
        $ADUser = Get-ADUser -Identity "$($member.SamAccountName)" -Properties DisplayName, EmailAddress, SamAccountName | Select-Object -Property DisplayName, EmailAddress, SamAccountName
        $memberArray += $ADuser
    }
    return $memberArray
}

function getArrayComparison {
    <#
    .SYNOPSIS
        Compares two arrays and searches for matches, or missing items using a
        defined field.

    .DESCRIPTION
        getArrayComparison is a function that returns a list of matches, or missing
        entries from the first array defined against the second. The field to search
        the array of objects is defined as a string and must match in both arrays.

    .PARAMETER Array1
        The source array

    .PARAMETER Array2
        The compared aray, entries that exist here will not be searched against array1

    .EXAMPLE
         getArrayComparison -Array1 $MembersOfGroup -Array2 $CSVImport -Field "EmailAddress"


    .NOTES
        Author:  Josh Litton
    #>
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [PSObject]$Array1,
        [Parameter(Mandatory=$true, Position = 1)]
        [PSObject]$Array2,
        [Parameter(Mandatory=$true, Position = 2)]
        [string]$Field,
        [switch]$nomatch
    )
    $myArray1 = $Array1 | Select-Object -ExpandProperty $Field
    $myArray2 = $Array2 | Select-Object -ExpandProperty $Field
    if ($nomatch) {
        $results = $myArray1 | Where-Object { $_ -notin $myArray2 }
    } else {
        $results = $myArray1 | Where-Object { $_ -in $myArray2 }
    }
    return $results
}


function Set-ExtensionAttribute {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position=0)]
        [String] $Identity,
        [parameter(Mandatory = $true, Position=1)]
        [String] $Attribute,
        [parameter(Mandatory = $false, Position=2)]
        [String] $Value,
        [parameter(Mandatory = $false)]
        [Switch] $Clear,
        [parameter(Mandatory = $false)]
        [Switch] $Replace
    )
    # Validate our identity exists before attempting edits
    try {$user = Get-ADUser -Identity $Identity -ErrorAction Stop} catch {throw "Error: Could not find user with identity $Identity"}

    if ($Clear) {
        # If Clear switch is enabled, clear the attribute first
        Try {Set-ADUser "$Identity" -Clear "$Attribute"} Catch {throw "Error: Unable to clear attribute $Attribute from $Identity"}
        # If no Value is assigned, then exit the function
        if ([string]::IsNullOrWhiteSpace($Value)) {
            if ($DEBUG -eq "1"){Log "DEBUG", "Attribute $Attribute on $Identity cleared."}
            return "$Attribute cleared"
        }
    }
    # If Value is not defined, inform user
    if (-not $Value) {throw "Error: Value not provided. A value is required if not using -Clear"}
    if ($Replace) {
        # If Replace switch is enabled, we use the -Replace action, this will replace attributes without values like Add. 
        Try {Set-ADUser "$Identity" -Replace @{$Attribute = "$Value"}} Catch {throw "Error: Unabled to replace $Attribute for $Identity"}
    } else {
        Try {Set-ADUser "$Identity" -Add @{$Attribute = "$Value"} } Catch {throw "Error adding attribute value - you may need to replace or clear the attribute"}
    }
    if ($DEBUG -eq "1"){Log "DEBUG", "Attribute $Attribute on $Identity set to value: $value"}
}

main