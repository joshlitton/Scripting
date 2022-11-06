### Specify our Constants
# JSS API - Web Help Desk
$creds = "anNzYXBpc2NvdGNod2hkOnlvbmRlci1FUVVBVEUzbmV3"
# Serial Number Array
$serials = [System.Collections.ArrayList]::new()

# SQL Details
$DBServer = "sql01-service.plcscotch.wa.edu.au"
$Database = "whd-service"

# Headers to Generate Bearer Token
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $creds")
$headers.Add("Content-Type", "application/json")
$headers.Add("Cookie", "APBALANCEID=aws.apse2-std-pelican1-tc-3")

Write-Host "Registering Bearer Token for script run"
$token = Invoke-RestMethod 'https://jss.plcscotch.wa.edu.au:8443/api/v1/auth/token' -Method 'POST' -Headers $headers

Write-Host "Updating Authorization to use Token"
# Update Authorization Header to use token. 
$headers.Authorization = "Bearer $($token.token)"
Start-Sleep -Seconds 3

# Get ALL Computers in Jamf Pro
$computers = Invoke-RestMethod 'https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory?section=GENERAL&section=HARDWARE&page=0&page-size=1000' -Method 'GET' -Headers $headers

# Calculate the pages required (roud down because we start at 0)
$pages = [math]::Floor($computers.totalCount / 1000)

# Iterate through all pages
foreach($i in 0..$pages){
        Write-Host "Collecting page $i of $pages"
        $computers = Invoke-RestMethod "https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory?section=GENERAL&section=HARDWARE&page=$i&page-size=1000" -Method 'GET' -Headers $headers

        # Loop through each computer on the page
        foreach ($computer in $computers.results){
            if ($computer.general.site.name -eq "Scotch"){
                Write-Host "Device $($computer.hardware.serialNumber) is assigned to scotch!" -BackgroundColor Green
                $serials.Add("$($computer.hardware.serialNumber)")
            } else {
                Write-Host "Not a scotch device"
            }
        }
}


### Loop through the Serial numbers we identified
### 1. Query SQL
### 2. Get Computer Jamf ID
### 3. Update AssetTag in Jamf
Write-Host -BackgroundColor White -ForegroundColor Black "Processing $($serials.Count) computers. Please wait..."
foreach ($s in $serials){
    #Write-Host $s
    $q = "SELECT * FROM whd.ASSET WHERE SERIAL_NUMBER='$s'"
    try {$return = Invoke-sqlcmd -serverinstance $DBServer -database $Database -query $q -ErrorAction Stop}
    catch {throw "Error connecting to SQL server, exiting script"}

    ### Get Computer ID with SerialNumber
    $response = Invoke-RestMethod "https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory?section=GENERAL&page=0&page-size=0&filter=hardware.serialNumber%3D%3D%22$($s)%22" -Method 'GET' -Headers $headers
    #Write-Host "Computer ID is: "$response.results.id
    
    # Regex pattern for AssetTag SCT#####
    if ($return.ASSET_NUMBER -match 'SCT[0-9]{4}.*')
    {
        Write-Host "Updating $s's AssetTag" -BackgroundColor Green
        Start-Sleep -Millisecond 100
        ### Update AssetTag in Jamf
        $body = "{`n    `"general`": {`n        `"assetTag`": `"$($return.ASSET_NUMBER)`"`n    }`n}"
        Try {Invoke-RestMethod "https://jss.plcscotch.wa.edu.au:8443/api/v1/computers-inventory-detail/$($response.results.id)" -Method 'PATCH' -Headers $headers -Body $body} 
        catch {Write-Host -Background Red "Error updating $s's AssetTag in Jamf"}
    } else {
        Write-Host -BackgroundColor Yellow "$s does not have a valid AssetTag"
    }
}