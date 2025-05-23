cls  # Clear the console screen

# Path to the main save file
$path = "C:\Temp\UserPeakIdleManager\savefile.json"

# Path to the backup save file
$path2 = "C:\Temp\UserPeakIdleManager\savefileBackup.json"

# Create a backup of the JSON file
Copy-Item -Path $path -Destination $path2 -Force

# Read the JSON file and convert it to a PowerShell object
$savefile = Get-Content $path -Raw | ConvertFrom-Json

# If the current date (formatted as yyyy.MM.dd) is different from the stored one
if ((Get-Date) -ne $savefile.today) {
    $savefile.today = Get-Date -Format yyyy.MM.dd

    # New calendar day: reset daily peak
    if ($savefile.today -ne $savefile.yesterday) {
        $savefile.peakOfLastDay = $savefile.peakOfDay
        $savefile.peakOfDay = 0
    }

    # If today is Monday: reset weekly peak
    if ($savefile.today.DayofWeek -eq "Monday") {
        $savefile.peakOfLastWeek = $savefile.peakOfWeek
        $savefile.peakOfWeek = 0
    }

    # If it's the first day of the month: reset monthly peak
    if ($savefile.today.Day -eq 1) {
        $savefile.peakOfLastMonth = $savefile.peakOfMonth
        $savefile.peakOfMonth = 0
    }
}

# Check if the current user session count exceeds any of the peak records
if ((Get-RDUserSession).Count -gt $savefile.peakOfDay) {
    $savefile.peakOfDay = (Get-RDUserSession).Count

    if ((Get-RDUserSession).Count -gt $savefile.peakOfWeek) {
        $savefile.peakOfWeek = (Get-RDUserSession).Count

        if ((Get-RDUserSession).Count -gt $savefile.peakOfMonth) {
            $savefile.peakOfMonth = (Get-RDUserSession).Count
        }
    }
}

# Prepare a list of current user sessions
$userConnections = @()

foreach ($connection in Get-RDUserSession) {
    $userConnections += [PSCustomObject]@{
        SessionId       = $connection.SessionId
        SessionState    = $connection.SessionState
        IdleTime        = $connection.IdleTime
        UserName        = $connection.UserName
        ServerIPAddress = $connection.ServerIPAddress
    }
}

# Show current peak connection count
Write-Host "There's $((Get-RDUserSession).Count) connections."
Write-Host ""

# Display the status of each user session
foreach ($session in $userConnections) {
    switch ($session.SessionState) {
        STATE_ACTIVE       { $result = "The Connection $($session.SessionId) is active" }
        STATE_DISCONNECTED { $result = "The Connection $($session.SessionId) is disconnected" }
        STATE_CONNECTED    { $result = "The Connection $($session.SessionId) is connected" }
    }

    Write-Host $result

    # Warn if idle time exceeds 1 hour
    if ($session.IdleTime -gt 3600000) {
        Write-Host "This session will be disconnected."
    }
}

# Update "yesterday" at 11 PM
if ((Get-Date).Hour -eq 23) {
    $savefile.yesterday = $savefile.today
}

# Output the updated object to the console
Write-Host $savefile

# Test remote WSMan connectivity to the RDS broker
Invoke-Command -ComputerName "BAS1-VM-RDS03" -ScriptBlock {
    Test-WSMan -ComputerName "BAS1-VM-Broker"
}

# Write updated data back to the JSON file
$savefile | ConvertTo-Json | Out-File -FilePath $path -Encoding utf8
