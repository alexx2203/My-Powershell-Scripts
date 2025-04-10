# Define a placeholder value for users who have never logged in
$notactive = 'Never logged in'

# Query all Active Directory users with specific properties
$users = Get-ADUser -Filter * -Properties Surname, GivenName, lastLogonTimestamp |

    # Filter out entries that do not have both a first name and a last name
    # (This helps exclude system accounts, service accounts, or improperly configured objects)
    Where-Object {
        $_.GivenName -ne $null -and $_.Surname -ne $null
    } |

    # Select and format the desired properties
    Select-Object Surname, GivenName, @{
        Name = 'lastLogonTimestamp'

        # Convert the Windows file time to a human-readable datetime format
        Expression = {
            if ($_.lastLogonTimestamp) {
                [DateTime]::FromFileTime($_.lastLogonTimestamp)
            } else {
                $notactive  # Use the placeholder text for missing timestamps
            }
        }
    }

# Convert result to array to ensure consistent object handling
$userArray = @($users)


#foreach($entry in $user){
#if ($entry.lastLogonTimestamp -ne $null){
#Write-Host $($entry.Surname) $($entry.GivenName) $([DateTime]::FromFileTime($entry.lastLogonTimestamp))}
#else {Write-Host $($entry.Surname) $($entry.GivenName) $notactive
#}}


$user | Format-Table Surname,  Givenname, lastLogonTimestamp