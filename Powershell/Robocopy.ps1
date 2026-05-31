# -------------------------------
# Robocopy Migration Script
# Copies Z:\ -> D:\ preserving NTFS permissions
# Safe to re-run (copies only newer/changed files)
# -------------------------------

$Source      = "Z:\"
$Destination = "D:\"
$LogPath     = "C:\Logs\Z_to_D_robocopy.log"

# Ensure log directory exists
if (-not (Test-Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs" | Out-Null
}

Write-Host "=============================================="
Write-Host " Starting Robocopy from $Source to $Destination"
Write-Host " Log: $LogPath"
Write-Host "=============================================="
Write-Host ""

# Robocopy options:
# /E          - Copy all subfolders including empty ones
# /COPYALL    - Copy all file info, including security and owner
# /DCOPY:DATS - Copy directory Data, Attributes, Timestamps, Security
# /XO         - Skip older files (only newer/changed files copied)
# /ZB         - Restartable, fallback to backup mode if needed
# /R:3 /W:5   - Retry 3 times, wait 5 sec
# /MT:16      - Multithreaded (adjust as needed)
# /NP         - Don’t show % progress
# /NFL /NDL   - Reduce log noise
# /TEE        - Log + console output
# /LOG+       - Append to log file

$RoboArgs = @(
    "`"$Source`"", "`"$Destination`""
    "/E",
    "/COPYALL",
    "/DCOPY:DATS",
    "/XO",
    "/ZB",
    "/R:3",
    "/W:5",
    "/MT:16",
    "/NP",
    "/NFL",
    "/NDL",
    "/TEE",
    "/LOG+:$LogPath"
)

# Run robocopy
$process = Start-Process -FilePath "robocopy.exe" -ArgumentList $RoboArgs -Wait -PassThru

Write-Host ""
Write-Host "=============================================="
Write-Host " Robocopy completed with exit code: $($process.ExitCode)"
Write-Host " (0 or 1 normally indicates success)"
Write-Host "=============================================="