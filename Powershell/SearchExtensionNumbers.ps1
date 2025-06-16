
$extensionNumber="250"
$LDAPFilter="(&(objectClass=user)(memberOf=CN=Guildford Staff,OU=Legacy,OU=Staff,OU=Groups,OU=GGS,DC=internal,DC=ggs,DC=wa,DC=edu,DC=au)(ipPhone=$($extensionNumber)))"

Get-ADObject -LdapFilter "$($LDAPFilter)" -Properties ipPhone | FT Name, ipPhone, DistinguishedName