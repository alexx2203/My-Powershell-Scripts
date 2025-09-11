cls  # Konsole leeren

# =================================================
# 📂 Pfade zur Speicherstruktur
# =================================================

# Pfad zur Haupt-Speicherdatei
$path = "C:\Temp\UserPeakIdleManager\savefile.json"

# Pfad zur Backup-Datei
$path2 = "C:\Temp\UserPeakIdleManager\savefileBackup.json"

# =================================================
# 📜 Vorbereiten des Logs
# =================================================

# Initialisierung eines Objekts für Abas-spezifische Logs und Zähler
$abasLog = [PSCustomObject]@{
    Logs = @()
    Counter = $counter
}

# =================================================
# 💾 Backup-Vorgang
# =================================================

# Erstelle ein Backup der JSON-Datei (überschreibt vorhandenes Backup)
Copy-Item -Path $path -Destination $path2 -Force

# =================================================
# 📜 JSON-Datei einlesen
# =================================================

# Lade die JSON-Datei und konvertiere sie in ein PowerShell-Objekt
$savefile = Get-Content $path -Raw | ConvertFrom-Json

# =================================================
# 📅 Tageswechsel prüfen
# =================================================

# Prüfe, ob das gespeicherte Datum dem heutigen entspricht
if((Get-Date -Format yyyy.MM.dd) -ne $savefile.today){

    # Aktualisiere das heutige Datum im Speicherobjekt
    $savefile.today = Get-Date -Format yyyy.MM.dd

    # Wenn es ein neuer Tag ist, speichere den vorherigen Tagespeak
    if($savefile.today -ne $savefile.yesterday){
        $savefile.peakOfLastDay = $savefile.peakOfDay
        $savefile.peakOfDay = 0
    }

    # Wenn heute Montag ist, setze Wochenwerte zurück
    if(([datetime]$savefile.today).DayofWeek -eq "Monday"){
        $savefile.peakOfLastWeek = $savefile.peakOfWeek
        $savefile.peakOfWeek = 0
    }

    # Wenn heute der 1. des Monats ist, setze Monatswerte zurück
    if(([datetime]$savefile.today).Day -eq 1){
        $savefile.peakOfLastMonth = $savefile.peakOfMonth
        $savefile.peakOfMonth = 0
    }
}

# =================================================
# 🔍 Benutzerverbindungen analysieren
# =================================================

# Leere Liste für aktive Benutzerverbindungen
$userConnections = @()

# Leere Liste für spätere Log-Ausgaben
$logs = @()

# Sammle relevante Sitzungsinformationen für alle Benutzer
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

# =================================================
# 🧮 Anzahl aktueller Verbindungen anzeigen
# =================================================

# Logge die Anzahl der aktuellen Benutzerverbindungen
$logs += Write-Output "There's $($userConnections.Count) connections." 
$logs += Write-Output ""

# =================================================
# 🧭 Details zu jeder Sitzung
# =================================================

# Zähler für aktive Abas-Sitzungen (wineks-Prozess)
$totalCount = 0

foreach ($session in $userConnections){

    # Status der Sitzung anhand von SessionState prüfen
    switch ($session.SessionState){

        # Aktive Sitzung: Benutzer ist aktiv am System
        STATE_ACTIVE       { $result = "Session $($session.SessionId) for user '$($session.UserName)' is currently active on '$($session.HostServer)'."}

        # Getrennte, aber nicht geschlossene Sitzung
        STATE_DISCONNECTED { $result = "Session $($session.SessionId) for user '$($session.UserName)' on '$($session.HostServer)' is disconnected but remains open."}

        # Sitzung verbunden, aber inaktiv
        STATE_CONNECTED    { $result = "Session $($session.SessionId) for user '$($session.UserName)' is connected to '$($session.HostServer)' but not yet active."}
    }

    # Füge Ergebnis-Log hinzu
    $logs += Write-Output $result

    # Wenn der Benutzer inaktiv ist, Log-Eintrag mit Dauer
    $time = [TimeSpan]::FromMilliseconds($session.IdleTime)

    if($session.IdleTime -gt 300000){
        $logs += Write-Output "$($session.UserName) has been inactive for $(if($time.Hours -gt 0){"$($time.Hours) hours and"}($time.Minutes)) minutes."
        #[TimeSpan]::FromMilliseconds($session.IdleTime)
    }  
  
    # =================================================
    # 🔍 "wineks"/"Abas"-Prozesse prüfen
    # =================================================

    $abasLog = Invoke-Command -ComputerName $session.HostServer -ScriptBlock {
        param($sessionId, $idleTime, $hostname, $userName)

        # Initialisiere Logs und lokalen Zähler
        $invokeLogs = @()
        $counter = 0

        # Finde Prozesse dieser Sitzung
        $processes = @(
            Get-Process |
            Where-Object { $_.SessionID -eq $sessionId } |
            Select-Object SessionId, ProcessName, ID
        )

        # Überprüfe jeden Prozess in dieser Sitzung
        foreach ($process in $processes) {
            
            # Abas erkannt? Prozessname ist "wineks"
            if ($process.ProcessName -eq "wineks") { 
                $invokeLogs += "Abas active"
                $counter ++
                                
                # Falls Prozess über 1h inaktiv: Stoppen
                if($idleTime -gt 3600000){
                    $invokeLogs += "This process will be killed."
                    #Stop-Process -ID $process.Id -Force
                }
            }
            $logs += Write-Output "`r`n"
        }

        # Rückgabe des lokalen Logs und Zählers
        $abasLog = [PSCustomObject]@{
            Logs = $invokeLogs
            Counter = $counter
        }

        return $abasLog
      
    } -ArgumentList ($session.SessionId, $session.IdleTime, $session.HostServer, $session.UserName)
    
    # Abas-Zähler hochzählen
    $totalCount = $totalCount + $abasLog.Counter

    # Logs zur Liste hinzufügen
    $logs += $abasLog.Logs 
}

# =================================================
# 🧾 Zusammenfassung der Abas-Sitzungen
# =================================================

$abasResult = switch($totalCount){
    0 {"no"}
    1 {"1"}
    default{"$totalcount"}
}

# Log-Eintrag: Wie viele Abas-Sitzungen sind aktiv?
$logs += Write-Output "There $(if($totalCount -le 1){"is"}else{"are"}) $($abasResult) connection$(if($totalCount -gt 1){"s"}) with Abas."

# Alle Logs in die Konsole schreiben
foreach($log in $logs){
    Write-Host $log
}

# =================================================
# 📈 Peak-Werte prüfen & setzen
# =================================================

# Neuer Tages-, Wochen- oder Monatsrekord?
if($totalCount -gt $savefile.peakOfDay){
    $savefile.peakOfDay = $totalCount

    if($totalCount -gt $savefile.peakOfWeek){
        $savefile.peakOfWeek = $totalCount

        if($totalCount -gt $savefile.peakOfMonth){
            $savefile.peakOfMonth = $totalCount
        }
    }
}

# Logs in das Savefile eintragen
$savefile.logs = $logs

# =================================================
# 🕛 Tagesende markieren
# =================================================

# Um Mitternacht: Gestern aktualisieren
if((Get-Date).Hour -eq 23){
    $savefile.yesterday = $savefile.today
}

# =================================================
# 💾 Rückspeichern der JSON-Daten
# =================================================

# Objekt wieder in JSON umwandeln und speichern
$savefile | ConvertTo-Json | Out-File -FilePath $path -Encoding utf8
