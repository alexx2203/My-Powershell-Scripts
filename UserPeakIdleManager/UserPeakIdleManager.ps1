davor: 
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

danach: 
function abasExit() {
    param(
        $funcCode,
        [int]$sessionId
    )
    Write-Host "Ich bin auf dem Server drauf mit SessionID $($sessionId)"   
}

# Function definition as a string (used for remote execution)
$abasExitFunction = @'
function abasExit(){
    param(
        [int]$sessionId
    )
    Write-Host "Ich bin auf dem Server drauf mit SessionID $($sessionId)"   
}
'@

cls  # Clear the console

# Path to the main save file
$path = "C:\Temp\UserPeakIdleManager\savefile.json"

# Path to the backup file
$path2 = "C:\Temp\UserPeakIdleManager\savefileBackup.json"

# Create a backup of the JSON file
Copy-Item -Path $path -Destination $path2 -Force

# Read and parse the JSON file into a PowerShell object
$savefile = Get-Content $path -Raw | ConvertFrom-Json

# If today's date (formatted) doesn't match the saved one
if ((Get-Date) -ne $savefile.today) {
    $savefile.today = Get-Date -Format yyyy.MM.dd

    # New calendar day: reset daily stats
    if ($savefile.today -ne $savefile.yesterday) {
        $savefile.peakOfLastDay = $savefile.peakOfDay
        $savefile.peakOfDay = 0
    }

    # If today is Monday: reset weekly stats
    if ($savefile.today.DayofWeek -eq "Monday") {
        $savefile.peakOfLastWeek = $savefile.peakOfWeek
        $savefile.peakOfWeek = 0
    }

    # If it's the 1st day of the month: reset monthly stats
    if ($savefile.today.Day -eq 1) {
        $savefile.peakOfLastMonth = $savefile.peakOfMonth
        $savefile.peakOfMonth = 0
    }
}

# Check if the current user session count exceeds saved peaks
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

# Output the number of current connections
Write-Host "There's $((Get-RDUserSession).Count) connections."
Write-Host ""

# Loop through each session and process its state
foreach ($session in $userConnections) {
    switch ($session.SessionState) {
        STATE_ACTIVE       { $result = "The Connection $($session.SessionId) is active. Destination: $($session.ServerIPAddress)" }
        STATE_DISCONNECTED { $result = "The Connection $($session.SessionId) is disconnected. Destination: $($session.ServerIPAddress)" }
        STATE_CONNECTED    { $result = "The Connection $($session.SessionId) is connected. Destination: $($session.ServerIPAddress)" }
    }

    # Run remote command if session is on specific servers
    if ($session.ServerIPAddress -eq "10.27.0.132") {
        Invoke-Command -ComputerName "BAS1-VM-RDS02" -ArgumentList $abasExitFunction -ScriptBlock {
            param($abasExitFunction)
            abasExit($session.SessionId)  
        }
    }
    elseif ($session.ServerIPAddress -eq "10.27.0.133") {
        Invoke-Command -ComputerName "BAS1-VM-RDS03" -ArgumentList $abasExitFunction -ScriptBlock {
            abasExit($session.SessionId)  
        }
    }
    else {
        # Do nothing for other IPs
    }

    Write-Host $result

    # Notify if the session has been idle for more than 1 hour
    if ($session.IdleTime -gt 3600000) {
        Write-Host "This session will be disconnected."
    }
}

# Update 'yesterday' value at 11 PM
if ((Get-Date).Hour -eq 23) {
    $savefile.yesterday = $savefile.today
}

# Print the entire savefile object (for debugging/output)
Write-Host $savefile

# Save updated data back to JSON file
$savefile | ConvertTo-Json | Out-File -FilePath $path -Encoding utf8

<#
RDS Control Script Block

cls  # Clear console

# Counter for a specific process
$counter = 0

# Get all processes in session ID 991
$processes = @(
    Get-Process |
    Where-Object { $_.SessionID -eq "991" } |
    Select-Object SessionId, ProcessName, ID
)

# Check for processes named "wineks" in that session
foreach ($process in $processes) {
    Write-Host $process.ProcessName $process.Id $process.SessionId

    if ($process.ProcessName -eq "wineks") {
        Write-Host "Match found"
        $counter++
    }
}

# Optional: Inspect available members (properties/methods) of the process object
Get-Process |
Where-Object { $_.SessionID -eq "991" } |
Get-Member

# Optional: Kill a specific process by ID (example)
Stop-Process -ID 159064
#>