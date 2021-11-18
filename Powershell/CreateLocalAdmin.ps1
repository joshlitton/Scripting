$Localuseraccount = @{
Name = 'servite'
Password = ("Admin#123" | ConvertTo-SecureString -AsPlainText -Force)
AccountNeverExpires = $true
PasswordNeverExpires = $true
Verbose = $true
}

New-LocalUser @Localuseraccount
Add-LocalGroupMember -Group "Administrators" -Member "servite"
