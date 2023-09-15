### Include our tools
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

# Jamf Cloud uses TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Log-Message "INFO", "Starting Script"

### Specify our Constants
# JSS API - Web Help Desk
$creds = "anNzYXBpc2NvdGNoY29tbWFuZHM6aW5mbzdyYXcuTklDRQ=="
$groupID = "332"
$UpperLimit = 21 # This script will exit if more that X-1 devices fall into scope. 

# Headers to Generate Bearer Token
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $creds")
$headers.Add("Content-Type", "application/json")
$headers.Add("Cookie", "APBALANCEID=aws.apse2-std-pelican1-tc-3")

Log-Message "INFO", "Registering Bearer Token for script run"
$token = Invoke-RestMethod 'https://jss.plcscotch.wa.edu.au:8443/api/v1/auth/token' -Method 'POST' -Headers $headers

Log-Message "INFO", "Updating Authorization to use Token"
# Update Authorization Header to use token. 
$headers.Authorization = "Bearer $($token.token)"
Start-Sleep -Seconds 1


### Get device list by Group ID
$response = Invoke-RestMethod "https://jss.plcscotch.wa.edu.au:8443/JSSResource/advancedmobiledevicesearches/id/$groupID" -Method 'GET' -Headers $headers
[int]$totalDevices = $($response.advanced_mobile_device_search.mobile_devices.size)
[string]$regexPattern = $response.advanced_mobile_device_search.criteria.criterion | Where-Object {$_.search_type -like "*regex"} | Select-Object -ExpandProperty Value
Log-Message "DEBUG", "Extracted regex pattern from saved search: $regexPattern"

Log-Message "INFO", "Found $totalDevices devices, processing..."

if ($totalDevices -lt $UpperLimit) {
    foreach ($device in $($response.advanced_mobile_device_search.mobile_devices.mobile_device)) {
        Log-Message "BREAK", "--------------------------------------------------------"
        Log-Message "DEBUG", "Collecting information for device ID: $($device.id)"
        $details = Invoke-RestMethod "https://jss.plcscotch.wa.edu.au:8443/api/v2/mobile-devices/$($device.id)/detail" -Method 'GET' -Headers $headers
        # FirstName Surname - #### - AssetTag
        $deviceName = "$($details.location.realName) - Staff - $($details.assetTag)"
        #Log-Message "DEBUG", "$deviceName"
        if ($deviceName -match "$regexPattern")
        {
            Log-Message "INFO", "$deviceName matches regex pattern"
            try {
                $body = "{`n    `"name`": `"$($deviceName)`"`n}"
                Invoke-RestMethod "https://jss.plcscotch.wa.edu.au:8443/api/v2/mobile-devices/$($device.id)" -Method 'PATCH' -Headers $headers -Body $body
            } catch {
                Log-Message "ERROR", "FAILED TO SET DEVICE NAME"
            }
        } else {
            Log-Message "WARN", "$deviceName doesn't match regex, check all fields present in Jamf" 
        }
}
} else {
    Log-Message "ERROR", "Too many devices in saved search, upper limit restriction set to: $UpperLimit"
}
Log-Message "INFO", "Script finished running."