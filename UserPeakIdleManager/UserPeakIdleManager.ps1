cls  # Clear the console screen

# Path to the main save file
$path = "C:\Temp\UserPeakIdleManager\savefile.json"
# Path to the backup save file
$path2 = "C:\Temp\UserPeakIdleManager\savefileBackup.json"

# Create a backup of the save file
Copy-Item -Path $path -Destination $path2 -Force

# Load the save file and convert it from JSON to a PowerShell object
$savefile = Get-Content $path -Raw | ConvertFrom-Json

# If the current date is different from what's stored in the file
if((Get-Date) -ne $savefile.today){
    # Update today's date (as a string in yyyy.MM.dd format)
    $savefile.today = Get-Date -Format yyyy.MM.dd

    # If the day has changed, reset daily peak and update yesterday's value
    if($savefile.today -ne $savefile.yesterday){
        $savefile.peakOfLastDay = $savefile.peakOfDay
        $savefile.peakOfDay = 0
        $savefile.yesterday = $savefile.today
    }

    # If today is Monday, reset weekly peak
    if($savefile.today.DayofWeek -eq "Monday"){
        $savefile.peakOfLastWeek = $savefile.peakOfWeek
        $savefile.peakOfWeek = 0
    }

    # If it's the first day of the month, reset monthly peak
    if($savefile.today.Day -eq 1){
        $savefile.peakOfLastMonth = $savefile.peakOfMonth
        $savefile.peakOfMonth = 0
    }
}

# Update peak values if the current number of user sessions exceeds the previous peaks
if((Get-RDUserSession).Count -gt $savefile.peakOfDay){
    $savefile.peakOfDay = (Get-RDUserSession).Count

    if((Get-RDUserSession).Count -gt $savefile.peakOfWeek){
        $savefile.peakOfWeek = (Get-RDUserSession).Count

        if((Get-RDUserSession).Count -gt $savefile.peakOfMonth){
            $savefile.peakOfMonth = (Get-RDUserSession).Count
        }
    }
}

# Prepare a list to hold current session data
$userConnections = @()

# Gather session details from active Remote Desktop sessions
foreach ($connection in Get-RDUserSession){
    $userConnections += [PSCustomObject]@{
        SessionId = $connection.SessionId            
        SessionState = $connection.SessionState  
        IdleTime = $connection.IdleTime  
        UserName = $connection.UserName  
        ServerIPAddress = $connection.ServerIPAddress  
    }
}

# Output the current peak number of connections
Write-Host "There's $($savefile.peakOfDay) connections."
Write-Host ""

# Display the state of each session
foreach ($session in $userConnections){
    switch ($session.SessionState){
        STATE_ACTIVE       { $result = "The Connection $($session.SessionId) is active" }
        STATE_DISCONNECTED { $result = "The Connection $($session.SessionId) is disconnected" }
        STATE_CONNECTED    { $result = "The Connection $($session.SessionId) is connected" }
    }

    Write-Host $result

    # Warn if session idle time exceeds 1 hour (3600000 milliseconds)
    if($session.IdleTime -gt 3600000){
        Write-Host "This session will be disconnected."
    }
}

# Save the updated data back to the JSON file
$savefile | ConvertTo-Json | Out-File -FilePath $path -Encoding utf8
