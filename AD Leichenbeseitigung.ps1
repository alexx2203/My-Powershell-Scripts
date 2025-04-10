cls 
$notactive = "Nie angemeldet"
$user = @(Get-ADUser -Filter * -Properties Surname, GivenName, lastLogonTimestamp | 
    Where-Object {
    $_.GivenName -ne $null -and 
    $_.Surname -ne $null } |
    Select-Object -Property Surname, GivenName, lastLogonTimestamp) 
    
    

#foreach($entry in $user){
#if ($entry.lastLogonTimestamp -ne $null){
#Write-Host $($entry.Surname) $($entry.GivenName) $([DateTime]::FromFileTime($entry.lastLogonTimestamp))}
#else {Write-Host $($entry.Surname) $($entry.GivenName) $notactive
#}}


$user | Format-Table Surname,  Givenname, lastLogonTimestamp