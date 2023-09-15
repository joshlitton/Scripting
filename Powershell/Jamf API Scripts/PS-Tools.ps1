<#
.SYNOPSIS
This module provides some useful tools when building powershell automation
To utilise logging feature, please define a hashtable and call Set-LogFile
# $log = Set.LogFile 
#>

function Set-LogFile() {

BEGIN
{
    [hashtable]$return = @{}
}
PROCESS
{
$ScriptName = [io.path]::GetFileNameWithoutExtension($MyInvocation.ScriptName)
$logPath = "$([io.path]::GetDirectoryName($PSCommandPath))\Logs\$ScriptName"
$logFile = "$logPath\$(get-date -f yyyyMMddHHmmss).log"

if (-NOT $(Test-Path -Path "$logPath")) {
    #Write-Host "Creating directory: $logPath"
    New-Item -ItemType "directory" -Path "$($logPath)" -Force | Out-Null
    }
}

END
{
$return.Name = $ScriptName
$return.Path = $logPath
$return.File = $logFile

return $return
}
}

function Log-Message ($logLevel, $logString)
{
    Add-content $($log.File) -value "$(get-date -f HH:mm:ss) $($logLevel[0..6]) $($logString)"
}

#Example Usage:
#Log "INFO", "Staff Check Started"
#Log "WARNING", "The number of current staff ($($count)) was less than expected level of $($ExpectedStaffCount)"