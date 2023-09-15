## Please provide the password in Base64 encoding. Plain text is bad.

Import-Module Microsoft.PowerShell.LocalAccounts

$username = "scadmin"
$B64_pwd = "MVN1cmdpY2FsLVNlcnZpdGUhCg=="
$decode_pwd = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($B64_pwd)) | ConvertTo-SecureString -AsPlainText -Force

New-LocalUser -Name "$username" -Password $decode_pwd -AccountNeverExpires -PasswordNeverExpires -Verbose
Add-LocalGroupMember -Group "Administrators" -Member "$username"