### Include our tools and modules
try {
    Import-Module ".\PS-Tools.ps1" -force
    # We add this in our root script to ensure we get this scripts name
    [hashtable]$log = @{}
    $log = Set-LogFile
}
catch {
    Write-Host "Error loading supporting PowerShell Scripts" -BackgroundColor RED
    exit
}
Import-Module Microsoft.Graph.CloudCommunications
#Import-Module Microsoft.Graph.Users.Actions

##
## Constants 
##
$ApplicationID = "ca8940cc-af54-4ae7-bfd4-0e07542f9c54"
$TenatDomainName = "plcscotch.onmicrosoft.com"
$AccessSecret = "NEc8Q~5SagHdASgEyag-si3Il9zKE5UkbNKjhaLp"
$AADGroups=@(
    "647837cd-aeec-40ff-940a-0cb1575d5f0d" #sct_o365_SC_Files_JuniorSchool
    "6d239dfe-c5d3-446b-b204-faec4ab2ebbc" #sct_o365_SC_Files_MiddleSchool
    "c020177b-1e51-444b-ad09-b323140e7a6a" #sct_o365_SC_Files_SeniorSchool
)
    #"7390413b-dbca-45fe-a3c6-23f760ff6ad0" #Catalytic Test Group
    #"f77e677c-9c13-469f-b0e4-73cf15b07c44" #A5
    #"1988399a-573d-45d6-b6ed-7e5f445c2109"  #A3
# Variables
$CurrentYear =  $(Get-Date).Year
[System.DateTime]$MeetingStartTime =[System.DateTime]::Parse("$($CurrentYear)-01-01T05:00:00+08:00")
[System.DateTime]$MeetingEndTime = [System.DateTime]::Parse("$($CurrentYear)-12-31T09:30:00+08:00")
# Meeting Subject Prefix, Teachers name will be appended
$MeetingSubject = "Parent Teacher Student Interview"
$CurrentList = "./Exports/Current-MeetingsList.csv"
$RunningList = "./Exports/$($CurrentYear)-MeetingsList.csv"

$CleanUp = $False
function main {
    # Get a token using our App Registration
    $token = Get-GraphToken "client_credentials" "https://graph.microsoft.com/.default" $ApplicationID $AccessSecret $TenatDomainName
    # Connect to Graph with our Token
    Connect-MgGraph -AccessToken $token
    
    if ($CleanUp) {
        #Call functions
    }
    # Get list of users from the defined AAD groups
    $UserList = Get-TeachersList -GroupIDs $AADGroups
   
    # Reporting on any duplicate entries
    #Write-Host "Found $(($UserList | Group-Object -Property Id | Where-Object { $_.Count -gt 1 }).Count) duplicated IDs"
    # Loop through all users found in AAD Groups
    foreach ($user in $UserList){
        Write-Host "Processing $($user.displayname)"
        $meeting = Create-OnlineMeeting -User $user -MeetingSubject $MeetingSubject -StartDateTime $MeetingStartTime -EndDateTime $MeetingEndTime
        $user | Add-Member -MemberType NoteProperty -Name "MeetingLink" -Value $($meeting.JoinWebUrl)
        $user | Add-Member -MemberType NoteProperty -Name "OnlineMeetingId" -Value $($meeting.Id)
    }
    $UserList | Export-Csv -Path $CurrentList -NoTypeInformation -Force -
    Export-RunningMeetingList -Users $UserList -CSVPath $RunningList
    #$UserList | Export-Csv -Path "./$($CurrentYear)-PTSI-Links.csv" -Append -NoTypeInformation
    Log-Message "INFO", "Script finished running."
}
function Get-GraphToken {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [string]$Grant,
        [Parameter(Mandatory=$true, Position = 1)]
        [string]$Scope,
        [Parameter(Mandatory=$true, Position = 2)]
        [string]$Client_Id,
        [Parameter(Mandatory=$true, Position = 3)]
        [string]$Client_Secret,
        [Parameter(Mandatory=$true, Position = 4)]
        [string]$Tenant_Name
    )
    # Populate API Body
    $Body = @{
    Grant_Type = "client_credentials"
    Scope = "https://graph.microsoft.com/.default"
    client_Id = $Client_Id
    Client_Secret = $Client_Secret
    }
    try {
        $ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$Tenant_Name/oauth2/v2.0/token" -Method POST -Body $Body
    } catch {
        LOG-Message "ERROR", "Failed to acquire token - exiting script"
        exit
    }
    $token = $ConnectGraph.access_token
    LOG-Message "INFO", "Acquired token for Graph API"
    return $token
}
function Get-TeachersList {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [PSObject]$GroupIDs
    )
    $membersArray=@()
    foreach ($group in $GroupIDs) {
        foreach ($member in $(Get-MgGroupMember -GroupId $group -All)) {
                $membersArray += [PSCustomObject]@{
                    Id = $member.id
                    DisplayName = $member.AdditionalProperties.displayName
                    EmailAddress = $member.AdditionalProperties.mail
            }
        }
    }
    LOG-Message "INFO", "Collected $($membersArray.Count) users from defined groups"
    return $membersArray
}
function Create-OnlineMeeting {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [PSObject]$User,
        [Parameter(Mandatory=$true, Position = 1)]
        [string]$MeetingSubject,
        [Parameter(Mandatory=$true, Position = 2)]
        [System.DateTime]$StartDateTime,
        [Parameter(Mandatory=$true, Position = 3)]
        [System.DateTime]$EndDateTime
    )
    $params = @{
        ExternalId = "PTSI-$($CurrentYear)-$($User.Id)"
        StartDateTime = $StartDateTime
        EndDateTime = $EndDateTime
        Subject = "$MeetingSubject - $($User.DisplayName)"
    }
    $timeout = 10
    # Invoke API Command to check if meeting exists, if not, create it. (Uses ExternalID as the Unique Identifier)
    $meeting = Invoke-MgCreateOrGetUserOnlineMeeting -UserId $User.Id -BodyParameter $params
    while ($timeout -gt $i -and (-not $meeting)) {
        $i += 1
        # The invoke does not respond when creating a new meeting, run again until we see a confirmation - fail after 20 attempts (10s)
        $meeting = Invoke-MgCreateOrGetUserOnlineMeeting -UserId $User.Id -BodyParameter $params
        # Give the API time to breath
        sleep .5
    }
    # If $meeting is populated, an onlineMeeting exists - Lets set the rules of the meeting. 
    if ($meeting) {
        # Redeclare parameters for updating
        $params = @{
            Subject = "$MeetingSubject - $($User.DisplayName)"
            AllowMeetingChat = "disabled"
            LobbyBypassSettings = @{
                IsDialInBypassEnabled = $false
                Scope = "organizer"
            }
        }
        # Lets run an update to ensure we have the correct Team restrictions
        Update-MgUserOnlineMeeting -UserId $User.Id -OnlineMeetingId $meeting.Id -BodyParameter $params
        return $meeting
    } else {
        # If we couldn't create a meeting, return ERROR, this will appear in export. 
        return "ERROR: Failed to create an online meeting for $($User.DisplayName)"
    }
    
}
function Export-RunningMeetingList {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [PSObject]$Users,
        [Parameter(Mandatory=$true, Position = 1)]
        [string]$CSVPath
    )
    try {$Existing = Import-Csv -Path $CSVPath} catch {Write-Host "First run this year!"}
    $MissingEntries = Get-ArrayComparison -Array1 $Users -Array2 $Existing -Field "Id" -NoMatch
    $MissingEntries | Export-Csv -Path $CSVPath -Append -NoTypeInformation
}
function Get-ArrayComparison {
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
    .PARAMETER Field
        A string containing the unique identifier to check matches for
    .PARAMETER NoMatch
        Switch to check return items that don't match
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
        [AllowNull()]
        [PSObject]$Array2,
        [Parameter(Mandatory=$true, Position = 2)]
        [string]$Field,
        [switch]$NoMatch
    )
    if ($Array1 -ne $null -and $Array2 -ne $null) {      
        if ($nomatch) {
            $results = $Array1 | Where-Object { $_.$($Field) -notin $Array2.$($Field) }
        } else {
            $results = $Array1 | Where-Object { $_.$($Field) -in $Array2.$($Field) }
        }
    } elseif ($Array1 -ne $null -and $Array2 -eq $null) {
        $results = $Array1
    } else { 
        throw "Array 1 is empty - cannot compare an empty array."
    }
    return $results
}
# Cleanup And Remove functions TBC. Needs further testing. 
# Issue with DELETE onlineMeeting Method
# https://github.com/microsoftgraph/microsoft-graph-docs/issues/17590
function Invoke-Cleanup {
        Write-Host -BackgroundColor Yellow -ForegroundColor Black "WARNING - You are about to enter a destructive action, this will delete all Online Meetings from the spreadsheet."
        $response = Read-Host "To remove all online meetings, please enter the App registration Application ID"
        if ($response -eq $ApplicationID){
            # Get Users from CSV
            $csvPath = Read-Host "Enter path to CSV"
            Write-Host -BackgroundColor Red "ATTENTION - ABOUT TO DELETE ALL ONLINE MEETINGS"
            if ((Read-Host "Continue? (y/N)") -imatch "Y") {
                foreach ($user in (Import-Csv -Path "$csvPath")){
                    Write-Host " Deleting $($user.DisplayName)"
                    Remove-OnlineMeetings -User $user
                }
            }
            exit
        } else {
            Write-Host "Please disable CleanUp variable before next run."
            pause
            exit
        }
}
function Remove-OnlineMeetings {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [PSObject]$User
    )
    Remove-MgUserOnlineMeeting -UserId $User.Id -OnlineMeetingId $User.OnlineMeetingId -IfMatch
}

main