cls  # Clear console for better readability

# Path template for the later export file (including current date/time)
$path = "C:\Temp\PCActivity\PCActivity_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmm")

# Query all computer objects in AD with specific properties
$adcomp = @(
    Get-ADComputer -Filter * -Properties CN, LastLogonDate, DistinguishedName, OperatingSystem, Created |
    Where-Object {
        # Filter: Only computers in "OU=GPO-Computer" and Windows 10 systems
        ($_.DistinguishedName -match "OU=GPO-Computer" -and $_.OperatingSystem -match '10')
    } |
    Select-Object @{
        # Output: Name, Last login, Creation date, Operating system
        Name = "Name"
        Expression = { $_.CN }
    }, @{
        Name = "Last Login"
        Expression = { $_.LastLogonDate }
    }, @{
        Name = "Added to AD on"
        Expression = { $_.Created }
    }, @{
        Name = 'Operating System'
        Expression = { $_.OperatingSystem }
    }
)

# User interaction: Display results in GridView
&{
    do {
        $answer = (Read-Host("Would you like to display the data? y/n")).Trim().ToLower()
        if ($answer -eq 'y') {
            $adcomp | Out-GridView -Title 'AD User'
        }
        elseif ($answer -eq 'n') {
            return $null
        }
        else {
            Write-Host ('Invalid input')  # Hint for wrong input
        }
    } while ($answer -ne 'y' -and $answer -ne 'n')
}

# User interaction: Export results to CSV file
&{
    do {
        $answer = (Read-Host("Would you like to export the data? y/n")).Trim().ToLower()
        if ($answer -eq 'y') {
            # Check if export folder exists, create if not
            $test = Test-Path C:\Temp\Activity
            if ($test -ne $true) {
                New-Item -ItemType Directory -Path "C:\Temp\PCActivity"
            }
            # Export the results
            $adcomp | Export-Csv -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Path $path 
            # Confirmation message
            [System.Windows.Forms.Messagebox]::Show("The file was created under C:\Temp\PCActivity.", "Information", 'Ok', 'Information')
        }
    } while ($answer -ne 'y' -and $answer -ne 'n')
}
