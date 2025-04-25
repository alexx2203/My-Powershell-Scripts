cls
# Helper variables
$notAvailable = '----------'
# Today's date
$date = Get-Date
# Export path
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

# Output users from Active Directory as an object array
$userArray = @(Get-ADUser -Filter * -Properties SamAccountName, Surname, GivenName, lastLogon, DistinguishedName, Manager, Description, Created) | 
    Where-Object { 
    # Checks if the object has a first and last name to filter out e.g. server accounts (not 100% reliable, revise if possible)
        ($_.GivenName -ne $null -and 
        $_.Surname -ne $null)
    } |
    Select-Object @{
    # Uses AD entry 'SamAccountName' for the Username column
    Name = 'Username' 
    Expression = {$_.SamAccountName}
    }, @{
    # Uses AD entry 'Surname' for the LastName column
    Name = 'LastName' 
    Expression = {$_.Surname}
    }, @{
    # Uses AD entry 'GivenName' for the FirstName column
    Name = 'FirstName' 
    Expression = {$_.GivenName}
    }, @{
    # Uses AD entry 'DistinguishedName' to determine the Location
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
        if($_.Description -ne $null){
            $_.Description
        }
        else{
            $notAvailable
        }
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
            # Replace missing lastLogon with "----------"
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
# Create hashtable that maps manager names to their DNs
foreach ($user in $userArray){
    $lookup[$user.DN] = "$($user.LastName) $($user.FirstName)"
} 

# Replace manager DN with user-friendly name if available
foreach($user in $userArray){
    if($user.Manager -ne $null){
       $user.Manager = $lookup[$user.Manager]
    }
    else{
       $user.Manager = $notAvailable
    }
}

# Remove 'DN' from the final output
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
            $test = Test-Path C:\Temp # Checks if path exists
            if($test -ne $true){
                New-Item -ItemType Directory -Path "C:\Temp" # Create it if it doesn't
            }
            # Use UTF8 encoding to avoid display issues when importing to Access
            $userArray | Export-Csv -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Path $path
            [System.Windows.Forms.Messagebox]::Show("The file was created under C:\Temp.", "Information", '', 'Information')
        }
    } while ($answer -ne 'y' -and $answer -ne 'n')
}

