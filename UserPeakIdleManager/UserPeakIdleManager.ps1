cls  # Konsole leeren

# ================================
# 📂 Pfade zur Speicherstruktur
# ================================

# Pfad zur Haupt-Speicherdatei
$path = "C:\Temp\UserPeakIdleManager\savefile.json"

# Pfad zur Backup-Datei
$path2 = "C:\Temp\UserPeakIdleManager\savefileBackup.json"

# ================================
# 💾 Backup-Vorgang
# ================================

# Backup der JSON-Datei erstellen (überschreibt vorhandene Datei)
Copy-Item -Path $path -Destination $path2 -Force

# ================================
# 📜 JSON-Datei einlesen
# ================================

# Inhalt der JSON-Datei lesen und in ein PowerShell-Objekt umwandeln
$savefile = Get-Content $path -Raw | ConvertFrom-Json

# ================================
# 📅 Tageswechsel prüfen
# ================================

# Wenn das heutige Datum nicht dem gespeicherten entspricht
if((Get-Date -Format yyyy.MM.dd) -ne $savefile.today){

    # Heutiges Datum im Format yyyy.MM.dd speichern
    $savefile.today = Get-Date -Format yyyy.MM.dd

    # Falls das neue Datum nicht dem vorherigen entspricht
    if($savefile.today -ne $savefile.yesterday){
        $savefile.peakOfLastDay = $savefile.peakOfDay
        $savefile.peakOfDay = 0
    }

    # Wochenanfang? Dann Wochenwerte zurücksetzen
    if(([datetime]$savefile.today).DayofWeek -eq "Monday"){
        $savefile.peakOfLastWeek = $savefile.peakOfWeek
        $savefile.peakOfWeek = 0
    }

    # Monatsanfang? Dann Monatswerte zurücksetzen
    if(([datetime]$savefile.today).Day -eq 1){
        $savefile.peakOfLastMonth = $savefile.peakOfMonth
        $savefile.peakOfMonth = 0
    }
}

# ================================
# 🔍 Benutzerverbindungen analysieren
# ================================

# Vorbereitung: Leere Liste für aktuelle Verbindungen
$userConnections = @()

# Sammle Sitzungsdaten aller Benutzer in ein Objekt
foreach ($connection in Get-RDUserSession){
    $userConnections += [PSCustomObject]@{
        SessionId = $connection.SessionId            
        SessionState = $connection.SessionState  
        IdleTime = $connection.IdleTime  
        UserName = $connection.UserName  
        ServerIPAddress = $connection.ServerIPAddress
        HostServer = $connection.HostServer  
    }
}

# ================================
# 🧮 Anzahl aktueller Verbindungen anzeigen
# ================================

Write-Host "There's $((Get-RDUserSession).Count) connections."
Write-Host ""

# ================================
# 🧭 Details zu jeder Sitzung
# ================================

# Counter für die Abas Sitzungen
$totalCount = 0

foreach ($session in $userConnections){

    # Zustand der Sitzung beschreiben
    switch ($session.SessionState){
        STATE_ACTIVE       { $result = "The Connection $($session.SessionId) is active. Destination: $($session.HostServer)"}
        STATE_DISCONNECTED { $result = "The Connection $($session.SessionId) is disconnected. Destination: $($session.HostServer)" }
        STATE_CONNECTED    { $result = "The Connection $($session.SessionId) is connected. Destination: $($session.HostServer)" }
    }

    Write-Host $result
        

    # Remote-Befehl: Auf dem Zielserver Prozesse prüfen
    $totalCount += Invoke-Command -ComputerName $session.HostServer -ScriptBlock {
        param($sessionId, $idleTime, $hostname)

        

        # Ausgabe der Sitzung
        Write-Host "I'm on the Server $($hostname) with the SessionID $($sessionId)"  

        # Prozesse dieser Sitzung ermitteln
        $processes = @(
            Get-Process |
            Where-Object { $_.SessionID -eq $sessionId } |
            Select-Object SessionId, ProcessName, ID
        )

        # Durch alle gefundenen Prozesse iterieren
        foreach ($process in $processes) {
            
            # Falls "wineks" (abas) erkannt wird...
            if ($process.ProcessName -eq "wineks") { 
                Write-Host "Name $($process.ProcessName) ProzessID $($process.Id) SessionID $($process.SessionId)"
                Write-Host "Match found"
                $counter++
                
                # ...und Inaktivität über 1 Stunde besteht:
                if($idleTime -gt 3600000){
                    Write-Host "This process will be disconnected."
                    #Stop-Process -ID $process.Id
                }
            }
        }
        Write-Host ""
        return $counter 
    } -ArgumentList ($session.SessionId, $session.IdleTime, $session.HostServer, $counter) 
}

Write-Host $totalCount


# ================================
# 📈 Peak-Werte prüfen & setzen
# ================================

# Aktuelle Benutzeranzahl ist höher als der Tagespeak?
if($totalCount -gt $savefile.peakOfDay){
    $savefile.peakOfDay = $totalCount

    # Höher als Wochenpeak?
    if($totalCount -gt $savefile.peakOfWeek){
        $savefile.peakOfWeek = $totalCount

        # Höher als Monatspeak?
        if($totalCount -gt $savefile.peakOfMonth){
            $savefile.peakOfMonth = $totalCount
        }
    }
}


# ================================
# 🕛 Tagesende markieren
# ================================

# Wenn aktuelle Stunde == 23: gestern aktualisieren
if((Get-Date).Hour -eq 23){
    $savefile.yesterday = $savefile.today
}


# ================================
# 💾 Rückspeichern der JSON-Daten
# ================================

# Objekt wieder in JSON umwandeln und speichern
$savefile | ConvertTo-Json | Out-File -FilePath $path -Encoding utf8
