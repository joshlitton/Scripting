$plcscotch = "plcscotch.onmicrosoft.com"
$targetou = "DC=ad,DC=scotch,DC=wa,DC=edu,DC=au"

$users = Get-ADUser -Filter * -SearchBase $targetou -Properties SamAccountName, EmailAddress, ProxyAddresses

Foreach ($user in $users) {
    $change = $false #for each user instance, assume we do not need to make a change (ie. the proxy address does not exist)
    $toberemoved = @() #set removal list back to empty for the new user

    Foreach ($proxy in $user.ProxyAddresses) { #loop through user proxy addresses and add offending to list
        If ($proxy.Contains("$($plcscotch)")) {
            $toberemoved += $proxy #add the proxy address to the removal list
        }
    }

    Foreach ($address in $toberemoved) { #loop through offending proxy addresses and remove them from the user
        $user.ProxyAddresses.remove($address)
        Write-Host "Removing $address from $($user.Name)"
        $change = $true #we need to save the $user changes back to AD
    }

   if ($change) { $result = Set-AdUser -Instance $user } #write back to AD
}