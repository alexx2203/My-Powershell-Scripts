cls

# Helper variables
$notAvailable = '----------'

# Today's date
$date = Get-Date

# Export path
$path = "C:\Temp\AdUser_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmm")

# Hashtable for locations
$locations = @{
    'Ou=Admin'                  = 'Bassum'
    'Ou=Interne Dienste'         = 'Bassum'
    'OU=Bassum'                  = 'Bassum'
    'Ou=Delmenhorst'             = 'Delmenhorst'
    'Ou=Diepholz'                = 'Diepholz'
    'OU=Sulingen'                = 'Sulingen'
    'Ou=Syke'                    = 'Syke'
    'Ou=Weyhe'                   = 'Weyhe'
    'Ou=WfbM Ganderkesee'         = 'Ganderkesee'
    'Ou=WfbM Ganderkesee Werk2'   = 'Ganderkesee 2'
}

# Outputs the Active Directory users as an object array
$userArray = @(
    Get-ADUser -Filter * -Properties SamAccountName, Surname, GivenName, lastLogonDate, DistinguishedName, Manager, Description, Created
) |
Where-Object {
    ($_.GivenName -ne $null -and $_.Surname -ne $null)
} |
Select-Object @{
    Name       = 'Username'
    Expression = { $_.SamAccountName }
}, @{
    Name       = 'LastName'
    Expression = { $_.Surname }
}, @{
    Name       = 'FirstName'
    Expression = { $_.GivenName }
}, @{
    Name       = 'Location'
    Expression = {
        $match = @(
            foreach ($location in $locations.Keys) {
                if ($_.DistinguishedName -match $location) {
                    $locations[$location]
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
    Name       = 'Position'
    Expression = {
        if ($_.Description -ne $null) {
            $_.Description
        }
        else {
            $notAvailable
        }
    }
}, @{
    Name       = 'Manager'
    Expression = { $_.Manager }
}, @{
    Name       = 'CreatedOn'
    Expression = { $_.Created }
}, @{
    Name       = 'LastLogin'
    Expression = {
        if ($_.lastLogonDate) {
            $_.lastLogonDate
        }
        else {
            $notAvailable
        }
    }
}, @{
    Name       = 'InactiveSince'
    Expression = {
        if ($_.lastLogonDate) {
            ($date - $_.lastLogonDate).Days
        }
        else {
            $notAvailable
        }
    }
}, @{
    Name       = 'DN'
    Expression = { $_.DistinguishedName }
}

# Container for the hashtable
$lookup = @{}

# Hashtable mapping manager names to their DNs
foreach ($user in $userArray) {
    $lookup[$user.DN] = "$($user.LastName) $($user.FirstName)"
}

# Replace managers
foreach ($user in $userArray) {
    if ($user.Manager -ne $null) {
        $user.Manager = $lookup[$user.Manager]
    }
    else {
        $user.Manager = $notAvailable
    }
}

# Removes "DN" from the overview
$userArray | ForEach-Object {
    $_.PSObject.Properties.Remove('DN')
}

&{
    do {
        $answer = (Read-Host("Would you like to display the data? y/n")).Trim().ToLower()
        if ($answer -eq 'y') {
            $userArray | Out-GridView -Title 'AD User'
        }
        elseif ($answer -eq 'n') {
            return $null
        }
        else {
            Write-Host ('Invalid input')
        }
    } while ($answer -ne 'y' -and $answer -ne 'n')
}

&{
    do {
        $answer = (Read-Host("Would you like to export the data? y/n")).Trim().ToLower()
        if ($answer -eq 'y') {
            $test = Test-Path C:\Temp
            if ($test -ne $true) {
                New-Item -ItemType Directory -Path "C:\Temp"
            }
            $userArray | Export-Csv -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Path $path
            [System.Windows.Forms.Messagebox]::Show("The file was created under C:\Temp.", "Information", 'Ok', 'Information')
        }
    } while ($answer -ne 'y' -and $answer -ne 'n')
}
