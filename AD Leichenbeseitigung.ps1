# Helper variables
$notAvailable = '----------'
# Today's date
$date = Get-Date
# A hashtable for locations. When a name is recognized in an object's OU, the location is assigned.
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
$userArray = @(Get-ADUser -Filter * -Properties SamAccountName, Surname, GivenName, lastLogon, DistinguishedName, Manager, Description, Created) | 
    Where-Object { 
        # Checks if the object has both a first and last name (e.g., to filter out server names)
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
                # Collects all locations based on OU matches. See hashtable above.
                foreach($location in $locations.Keys){
                    if($_.DistinguishedName -match $location){
                        ($locations[$location])
                    }
                }
            )
            if ($match -ne $null) {
                $match -join ", "
            }
            else {
                $notAvailable
            }
        }
    }, @{
        Name = 'Position'
        Expression = {
            $_.Description
        }
    }, @{
        Name = 'Manager'
        Expression = {
            $_.Manager
        }
    }, @{
        Name = 'Created_On'
        Expression = {
            ($_.Created).ToString("yyyy-MM-dd")
        }
    }, @{
        Name = 'Last_Login'
        Expression = {
            # If last login exists...
            if ($_.lastLogon){ 
                # Convert Windows file time to readable date  
                (([DateTime]::FromFileTime($_.lastLogon)).Date).ToString("yyyy-MM-dd")
            } else { 
                # Replace missing lastLogon with "Not logged in"
                $notAvailable
            }
        }
    }, @{
        Name = 'Inactive_Since' 
        Expression = {
            if ($_.lastLogon){
                # Subtracts last login from today's date 
                ($date - [datetime]::FromFileTime($_.lastLogon)).Days
            } else {
                # Replaces the empty field with "Not logged in"
                $notAvailable
            }
        }
    }, @{
        Name = 'DN'
        Expression = {$_.DistinguishedName}
    }

# "Container for the hashtable"
$lookup = @{}
# Create a hashtable that maps the DN of managers to their readable name
foreach ($user in $userArray){
    $lookup[$user.DN] = "$($user.LastName) $($user.FirstName)"
} 

# Replace manager DN with a readable name if available
foreach ($user in $userArray){
    if ($user.Manager -ne $null) {
        $user.Manager = $lookup[$user.Manager]
    }
    else {
        $user.Manager = $notAvailable
    }
}

# Ask if the user wants to display the data
do {
    $answer = (Read-Host("Do you want to display the data?" + ' y/n')).Trim().ToLower()
    if ($answer -eq 'y') {
        $userArray | Out-GridView -Title 'AD Users'
    } elseif ($answer -eq 'n') {
        return $null
    } else {
        Write-Host ('Invalid input')
    }
} while ($answer -ne 'y' -and $answer -ne 'n')

# Ask if the user wants to export the data
do {
    $answer = (Read-Host("Do you want to export the data?" + ' y/n')).Trim().ToLower()
    if ($answer -eq 'y') {
        # Export-CSV -Path yourpath.csv 
    }
} while ($answer -ne 'y' -and $answer -ne 'n')