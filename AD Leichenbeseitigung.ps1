# Helper variables
$notactive = "----------"
# Today's date
$date = Get-Date
# A hashtable for locations. When a name is matched within an object's OU, the location is assigned.
$locations = @{
    'Ou=Admin' = 'Bassum'
    'Ou=Interne Dienste' = 'Bassum'
    'OU=Bassum' = 'Bassum'
    'Ou=Delmenhorst' = 'Delmenhorst'
    'Ou=Diepholz' = 'Diepholz'
    'OU=Sulingen' = 'Sulingen'
    'Ou=Syke' = 'Syke'
    'Ou=Weyhe' = 'Weyhe'
    'Ou=WfbM Ganderkesee' = 'Ganderkesee'
    'Ou=WfbM Ganderkesee Werk2' = 'Ganderkesee 2'
}

# Outputs Active Directory users as an object array
$userArray = @(Get-ADUser -Filter * -Properties SamAccountName, Surname, GivenName, lastLogon, DistinguishedName) | 
    Where-Object { 
        # Checks if the object has both a first and last name (to filter out e.g. server accounts)
        ($_.GivenName -ne $null -and 
         $_.Surname -ne $null)
        # $_.SamAccountName -match '[a-zäöü]'
    } |
    Select-Object @{
        # Uses 'SamAccountName' from AD for the Username column
        Name = 'Username' 
        Expression = {$_.SamAccountName}
    }, @{
        # Uses 'Surname' from AD for the LastName column
        Name = 'LastName' 
        Expression = {$_.Surname}
    }, @{
        # Uses 'GivenName' from AD for the FirstName column
        Name = 'FirstName' 
        Expression = {$_.GivenName}
    }, @{
        # Uses 'DistinguishedName' from AD to determine the location
        Name = 'Location' 
        Expression = {
            $match = @(
                # Collects all matching locations according to the user's OU(s). See hashtable above.
                foreach($location in $locations.Keys){
                    if($_.DistinguishedName -match $location){
                        ($locations[$location])
                    }
                }
            )
            $match -join ", "
        }
    }, @{
        Name = 'Last_Login'
        Expression = {
            # If a last login exists...
            if ($_.lastLogon){ 
                # Convert Windows file time to readable date  
                (([DateTime]::FromFileTime($_.lastLogon)).Date).ToString("yyyy-MM-dd")
            } else { 
                # Replace missing lastLogon with "Not logged in"
                $notactive
            }
        }
    }, @{
        Name = 'Inactive_since' 
        Expression = {
            if($_.lastlogon){
                # Subtracts last login from today's date 
                ($date - [datetime]::FromFileTime($_.lastLogon)).Days
            } else {
                # Replaces the empty field with "Not logged in"
                $notactive
            }
        }
    }

$userArray | Format-Table Username, LastName, FirstName, Last_Login, Inactive_since, Location
