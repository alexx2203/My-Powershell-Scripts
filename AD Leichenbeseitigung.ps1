# Helper variables
$notAvailable = '----------'
# Today's date
$date = Get-Date
# Path for the export
$path = "C:\Temp\AdUser_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmm")
# A hashtable for the locations; once the name is recognized in the OUs of the objects, the location is assigned.
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

# Outputs the users from Active Directory as an object array
$userArray = @(Get-ADUser -Filter * -Properties SamAccountName, Surname, GivenName, lastLogon, DistinguishedName, Manager, Description, Created) | 
    Where-Object { 
    # Checks if the object has a first and last name to filter out e.g. server accounts (not 100% reliable, revise if possible)
        ($_.GivenName -ne $null -and 
        $_.Surname -ne $null)
    } |
    Select-Object @{
    # Uses the AD entry 'SamAccountName' for the Username column
    Name = 'Username' 
    Expression = {$_.SamAccountName}
    }, @{
    # Uses the AD entry 'Surname' for the LastName column
    Name = 'LastName' 
    Expression = {$_.Surname}
    }, @{
    # Uses the AD entry 'GivenName' for the FirstName column
    Name = 'FirstName' 
    Expression = {$_.GivenName}
    }, @{
    # Uses the AD entry 'DistinguishedName' to determine the Location
    Name = 'Location' 
    Expression = {
        $match = @(
           foreach($location in $locations.Keys){
                if($_.DistinguishedName -match $location){
                    ($locations[$location])
                }
            }
        )
        if($match -ne $null){
            $match -join ", "
        }
        else{
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
    Name = 'CreatedOn'
    Expression = {
        ($_.Created).ToString("yyyy-MM-dd")
    }
    }, @{
    Name = 'LastLogin'
    Expression = {
        # If last login exists...
        if ($_.lastLogon){ 
            # Convert Windows TimeFile to readable date
            (([DateTime]::FromFileTime($_.lastLogon)).Date).ToString("yyyy-MM-dd")
        } 
        else { 
            # Replace missing lastLogon with "Never logged in"
            $notAvailable
        }
    }
    }, @{
    Name = 'InactiveSince' 
    Expression = {
        if($_.lastLogon){
            # Subtract last login from today's date
            ($date - [datetime]::FromFileTime($_.lastLogon)).Days
        }
        else{
            # Replace empty field with "Never logged in"
            $notAvailable
        }
    }
    }, @{
    Name = 'DN'
    Expression = {$_.DistinguishedName}
}

# "Container for the hashtable"
$lookup = @{}
# Create hashtable mapping manager names to DNs
foreach ($user in $userArray){
    $lookup[$user.DN] = "$($user.LastName) $($user.FirstName)"
}

# If manager is present, replace DN with user-friendly name
foreach($user in $userArray){
    if($user.Manager -ne $null){
       $user.Manager = $lookup[$user.Manager]
    }
    else{
       $user.Manager = $notAvailable
    }
}

# Remove the 'DN' property from the output
$userArray | ForEach-Object {
    $_.PSObject.Properties.Remove('DN')
}

&{ 
    do {
        $answer = (Read-Host("Would you like to display the data?" +' y/n')).Trim().ToLower()
        if($answer -eq 'y'){
            $userArray | Out-GridView -Title 'AD User'
        } elseif ($answer -eq 'n'){
            return $null
        } else {
            Write-Host ('Invalid input')
        }
    } while ($answer -ne 'y' -and $answer -ne 'n')
}

&{
    do {
        $answer = (Read-Host("Would you like to export the data?" +' y/n')).Trim().ToLower()
        if($answer -eq 'y'){
            $test = Test-Path C:\Temp # Check if path exists
            if($test -ne $true){
                New-Item -ItemType Directory -Path "C:\Temp" # If not, create it
            }

            $userArray | Export-Csv -NoTypeInformation -Delimiter ';' -Path $path
            Write-Host "The file has been created in C:\Temp."
        }
    } while ($answer -ne 'y' -and $answer -ne 'n')
}
