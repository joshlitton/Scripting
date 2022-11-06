Log "INFO", "Staff Check Started"
"Staff Check Started"

$staff = invoke-sqlcmd -serverinstance "kiccentral" -database "KardiniaConnect" -query "select * from vCurrentStaff where CreateADAccount = 1"
$count = ([System.Data.DataRow[]]($staff)).count
if($count -lt $ExpectedStaffCount)
{
	Log "WARNING", "The number of current staff ($($count)) was less than expected level of $($ExpectedStaffCount)"
}

Foreach ($result in $staff)
{
	#setup variables for this user
	if($result.ADAccountOU -eq "Instrumental")
	{
		$ou = $InstrumentalStaffOU
	}
	else
	{
		if($result.ADAccountOU -ne "")
		{
			$ou = "OU=$($result.ADAccountOU),$($StaffOU)"
		}
		else
		{
			$ou = $StaffOU
		}
	}


	#check user has an AD account
	$adAccount = get-aduser -filter "EmployeeId -eq $($result.Id)" -SearchBase $StaffOU -Properties $StaffAdProperties

	if(-Not $adAccount)
	{
		# not found, check entire AD if not there then need to create an account
		$adAccount = get-aduser -filter "EmployeeId -eq $($result.Id)" -Properties $StaffAdProperties
		if(-Not $adAccount)
		{
			#Create Staff Account
			Log "INFO", "$($result.GivenName) $($result.Surname) Doesn't have an AD Account"

			if(-not $debug)
			{
				$adAccount = CreateUserAccount -UserType $StaffUserType -Id $result.id -Preferred $result.PreferredName -Surname $result.Surname -ou $ou
				if(-not $adAccount)
				{
					Log "ERROR", "Unable to create user account for $($result.GivenName) $($result.Surname)"
					continue
				}
			}else
			{
				Log "DEBUG", "Account would be created for $($result.GivenName) $($result.Surname)"
				continue
			}
		}
	}
	
	#check account is enabled
	if(-not $adAccount.enabled)
	{
		Log "INFO", "Account $($adAccount.samaccountname) is disabled"
		EnableUserAccount $adAccount
		set-aduser $adAccount -clear @("msExchHideFromAddressLists")
	}

	#check OU
	if( `
		$adAccount.distinguishedName -like "*OU=Admin,OU=Staff,OU=KIC Users,DC=kardinia,DC=local" `
		-or `
		$adAccount.distinguishedName -like "*OU=Information\, Communications & Technology,OU=College Staff,OU=Staff,OU=KIC Users,DC=kardinia,DC=local" `
		-or `
		$adAccount.distinguishedName -like "*OU=Other,OU=KIC Users,DC=kardinia,DC=local" `
	)
	{
		#Log "INFO", "User $($adAccount.SamaccountName) Is in a protected OU, do not move"
	}
	else
	{
		$currentOU = ($adAccount.distinguishedName -Split "OU=")[1]
		if(-not ($currentOU -eq ($ou -Split "OU=")[1]))
		{
			#Move AD Account
			if(-not $debug)
			{
				try
				{
					Move-ADObject $adAccount -targetpath $ou
					$adAccount = get-aduser $adAccount.samaccountname -Properties $StaffAdProperties
					Log "INFO", "Moved Account '$($adAccount.SamaccountName)' To: $($ou)"
				}
				catch
				{
					Log "ERROR", "Unable to move account '$($adAccount.SamaccountName)' To: $($ou). Check the destination ou exists and that the user account is not protected"
				}
			}
			else
			{
				Log "DEBUG", "Account $($adAccount.SamaccountName) Would be moved to $($ou)"
			}
		}
	}

	#Sync AD Attributes with db data

	$replace = @{}
	if($adAccount.sn -ne $result.Surname.Trim()) {$replace.add("sn", $result.Surname.Trim())}
	if($adAccount.givenName -ne $result.PreferredName.Trim()) {$replace.add("givenName", $result.PreferredName.Trim())}
	if($adAccount.description -ne $StaffUserType) {$replace.add("description", $StaffUserType)}
	if($adAccount.department -ne "$($result.Department) - $($result.Category)") {$replace.add("department", "$($result.Department) - $($result.Category)")}
	if($adAccount.telephoneNumber)
	{
		if($adAccount.telephoneNumber -ne $result.Phone) {$replace.add("telephoneNumber", $result.Phone)}
		if(([String]$result.Phone).Trim() -ne "")
		{
			if($adAccount.ipPhone -ne "KIC") {$replace.add("ipPhone", "KIC")}
		}else
		{
			$replace.add("ipPhone", "")
		}
	}
	else
	{
		if(([String]$result.Phone).Trim() -ne "") {
			$replace.add("telephoneNumber", $result.Phone)
			Log "Info", "Set ipPhone (not existing)"
			$replace.add("ipPhone", "KIC")
		}
	}
	if($adAccount.displayName -ne "$($result.PreferredName.Trim()) $($result.Surname.Trim())") {$replace.add("displayName", "$($result.PreferredName.Trim()) $($result.Surname.Trim())")}

	$office = $NULL
	if($result.Building -ne ([DBNull]::Value)) {if($result.Building.Trim() -ne "") {$office = $result.Building}}
	if($result.Room -ne ([DBNull]::Value)) {if($office){$office ="$($office): $($result.Room)"} else {$office = $result.Room}}

	if($adAccount.physicalDeliveryOfficeName -ne $office) {$replace.add("physicalDeliveryOfficeName", $office)}

	if($adAccount.extensionAttribute9)
	{
		if($adAccount.extensionAttribute9 -ne $result.Barcode) {$replace.add("extensionAttribute9", $result.Barcode)}
	}
	else
	{
		if($result.Barcode -ne ([DBNull]::Value))
		{
			if($result.Barcode.Trim() -ne "") {$replace.add("extensionAttribute9", $result.Barcode)}
		}
	}

	if($adAccount.otherIpPhone)
	{
		if($adAccount.otherIpPhone -ne $result.Voicemail) {$replace.add("otherIpPhone", $result.Voicemail)}
	}
	else
	{
		if($result.Voicemail -ne ([DBNull]::Value))	{$replace.add("otherIpPhone", $result.Voicemail)}
	}

	$voicemail = 0
	$phone = 0

	if([int]::tryparse($result.Voicemail, [ref] $voicemail) -and ($voicemail -ge 500 -and $voicemail -le 799)) {$ext1 = "VM Only"}
	elseif([int]::tryparse($result.Phone, [ref] $phone) -and ($phone -ne 300 -and $phone -ne 338)) {$ext1 = "UCA"}
	else {$ext1 = $adAccount.extensionAttribute1}

	if($adAccount.extensionAttribute1 -ne $ext1) {$replace.add("extensionAttribute1", $ext1)}
	if($adAccount.extensionAttribute4 -ne $StaffUserType) {$replace.add("extensionAttribute4", $StaffUserType)}
	if($adAccount.userPrincipalName -ne "$($adAccount.samaccountname)@kardinia.vic.edu.au") {$replace.add("userPrincipalName", "$($adAccount.samaccountname)@kardinia.vic.edu.au")}

	if($replace.count -gt 0)
	{
		$nullarr = @()
		$clear = @()
		foreach($key in $replace.keys)
		{
			if($replace[$key] -is [int]) { continue }
			if($replace[$key] -eq ([DBNull]::Value) -or $replace[$key] -eq $NULL -or $replace[$key].Trim() -eq "") {$nullarr += $key}
		}

		foreach($key in $nullarr)
		{
			$replace.remove($key)
			$clear += $key
		}

		if(-not $debug)
		{
			if($replace.count -gt 0)
			{
				set-aduser $adAccount -replace $replace
				Log "INFO", "Set the Following Attributes for user $($adAccount.SamaccountName): $($replace | out-string)"
			}
			if($clear.count -gt 0)
			{
				set-aduser $adAccount -clear $clear
				Log "INFO", "Cleared the Following Attributes for user $($adAccount.SamaccountName): $($clear | out-string)"
			}
		}
		else
		{
			if($replace.count -gt 0)
			{
				Log "DEBUG", "The Following Attributes would be set for user $($adAccount.SamaccountName): $($replace | out-string)"	
			}
			if($clear.count -gt 0)
			{
				Log "DEBUG", "The Following Attributes would be cleared for user $($adAccount.SamaccountName): $($clear | out-string)"	
			}
		}
	}

	$adAccount = get-aduser $adAccount.samaccountname -Properties $StaffAdProperties
	#Sync with Synergetic
	if(($adAccount.mail -and $adAccount.mail -ne $result.WorkEmailAddress) -or $adAccount.samaccountname -ne $result.NetworkLogin -or $adAccount.ExtensionAttribute4 -ne $StaffUserType)
	{
		SynergeticUpdate -user $adAccount -password $null
	}
}