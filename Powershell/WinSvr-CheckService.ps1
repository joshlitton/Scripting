# Catalytic IT
# Josh Litton - 23/07/2021
# The following script can be run from within an AD environment to check a specific service on all servers
# Developed for identifying CVE vulnerabilities

# Turn off error display
$ErrorActionPreference= 'silentlycontinue'
$service="Print Spooler"
$OU="OU=Trinity, DC=trn, DC=internal"
#$PatchKBs=@('5004954', '5004956', '5004953', '5004955', '5004948', '5004945', '5004947')
$servers=Get-ADComputer -Filter {OperatingSystem -like "*windows*server*" -and Enabled -eq $true} -SearchBase $OU -Properties *
ForEach ($svr in $servers) {
    If (Test-Connection -Count 1 -ComputerName $svr.DNSHostName -Quiet) {
        #Still in development
        #$hotfixes=Get-HotFix -ComputerName $svr.Name | Select-Object -Property HotFixID
        #$hfcheck=Compare-Object -IncludeEqual -ExcludeDifferent $PatchKBs $hotfixes
        #Write-Host $hfcheck

        $svc=Get-Service -ComputerName $svr.Name -Name $service
        if ( $? ) {
            Write-Host $svr.Name, $svc.Status -ForegroundColor White -BackgroundColor Red
        } else {
            Write-Host "$($svr.Name) could not find $($service)"
        }
    } else {
        Write-Host "$($svr.Name) is offline" -ForegroundColor Gray
    }
}
# Hang for user input
Read-Host -Prompt "Press Enter to exit"
