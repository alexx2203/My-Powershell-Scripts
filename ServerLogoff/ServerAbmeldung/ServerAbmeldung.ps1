Get-RDS# ─────────────────────────────────────────────────────────────────────────────
# 🎥 Transkript starten – für sauberes Debugging
# Erstellt eine Log-Datei mit sämtlicher Konsolen-Ausgabe.
# So kannst du später jeden Schritt nachvollziehen.
# ─────────────────────────────────────────────────────────────────────────────
Start-Transcript -Path "C:\Temp\MicosAbmeldung\debugkiller.log"

# ─────────────────────────────────────────────────────────────────────────────
# 🧽 Konsole säubern – nur für die Augen des Admins.
# Hat keinen Einfluss auf die Logik, macht die Ausgabe aber klarer.
# ─────────────────────────────────────────────────────────────────────────────
cls

# ─────────────────────────────────────────────────────────────────────────────
# 📥 Benutzername aus JSON-Datei laden
# Hier wird aus einer JSON-Datei der Benutzername geholt, 
# der später auf den RDS-Servern abgemeldet werden soll.
# ─────────────────────────────────────────────────────────────────────────────
$saveFilePath = "C:\Temp\MicosAbmeldung\user.json"
$savefile     = Get-Content -Path $saveFilePath
$user         = $savefile | ConvertFrom-Json

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host " [Info] Benutzer geladen: $($user.userName)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# 💻 Liste der Zielserver definieren
# Alle AD-Computer, deren Name mit „bas1-vm-rds“ beginnt, werden aufgelistet.
# Das sind die RDS-Server, die wir nacheinander überprüfen.
# ─────────────────────────────────────────────────────────────────────────────
$remoteServerLong = Get-RDServer -ConnectionBroker ... -Role RDS-RD-SERVER
$remoteServer = @()
foreach($server in $remoteServerLong){
    $remoteServer += $server.Server.Split(".")[0]
}

Write-Host "📡 Gefundene RDS-Server:" -ForegroundColor Magenta
$remoteServer | ForEach-Object { Write-Host "   → $($_)" -ForegroundColor DarkGreen }
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# 🔁 Remote-Abmeldung des Benutzers auf jedem Server
# Schleife läuft über alle gefundenen Server. 
# Auf jedem wird geprüft, ob der Benutzer aktiv ist. 
# Falls ja → Abmeldung, danach Abbruch der Schleife.
# ─────────────────────────────────────────────────────────────────────────────
foreach ($server in $remoteServer) {
    $info = $null
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkYellow
    Write-Host "[Check] Prüfe auf Server: $server ..." -ForegroundColor DarkGray
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkYellow

    try {
        # Invoke-Command: Führt den Codeblock direkt auf dem Zielserver aus
        Invoke-Command -ComputerName $server -InformationVariable info -InformationAction SilentlyContinue -ScriptBlock {
            param($user)

            # quser.exe listet aktive Sessions auf (Name, ID, Status etc.)
            $queryOutput = quser.exe
            $parsedUsers = @()

            # Debug-Ausgabe: Rohdaten von quser.exe anzeigen
            Write-Host "`n[Debug] Ausgabe von quser.exe:" -ForegroundColor DarkCyan
            $queryOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
            Write-Host ""

            foreach ($line in $queryOutput) {
                # Leere Zeilen überspringen
                if ($line.Trim() -eq "") { continue }

                # Eventuell führendes ">" entfernen, dann per Doppel-Leerzeichen splitten
                $parts = $line -replace '^\s*>?', '' -split '\s{2,}'

                # Nur verarbeiten, wenn die Zeile genug Spalten hat (≥ 6)
                if ($parts.Count -ge 6) {
                    $parsedUsers += [PSCustomObject]@{
                        userName     = $parts[0]  # Benutzername
                        session      = $parts[1]  # Session-Name
                        id           = $parts[2]  # Session-ID
                        status       = $parts[3]  # Status (aktiv, getrennt usw.)
                        idleTime     = $parts[4]  # Inaktivitätszeit
                        logontime  = $parts[5]  # Zeitpunkt der Anmeldung
                    }
                }
            }

            # Vergleich: Ist der aktuelle Benutzer in der Liste?
            foreach ($userInfo in $parsedUsers) {
                if ($userInfo.userName -eq $user.userName) {
                    Write-Host "[Abmeldung] Benutzer '$($userInfo.userName)' auf Session-ID $($userInfo.id)" -ForegroundColor Yellow
                    try {
                        # Session wird per logoff beendet
                        logoff $userInfo.id
                        Write-Host "[Erfolg] Benutzer erfolgreich abgemeldet." -ForegroundColor Green
                        Write-Host "[Info] Vorgang abgeschlossen – keine weiteren Server notwendig." -ForegroundColor Cyan
                        $success = $true
                        
                        # Mit „Write-Information“ markieren wir, dass wir abbrechen können
                        Write-Information "Abbruch" -Tags Abbruch
                    } catch {
                        Write-Host "[Fehler] Abmeldung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }

            # Falls der Benutzer auf diesem Server gar nicht existierte
            if (-not $success) {
                Write-Host "[Hinweis] Benutzer nicht gefunden." -ForegroundColor DarkGray
            }

        } -ArgumentList $user

        # Prüfen, ob das „Abbruch“-Tag gesetzt wurde → dann aus der Schleife springen
        if ($info.Tags -contains 'Abbruch') {
            Write-Host "`n[Stop] Vorgang beendet – Benutzer wurde bereits erfolgreich abgemeldet." -ForegroundColor Magenta
            break
        }
               
    } catch {
        # Fehler beim Verbindungsaufbau zu einem Server (z. B. offline, Firewall blockt)
        Write-Host "[Fehler] Verbindung zu Server $($server) fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
    }      
}

# ─────────────────────────────────────────────────────────────────────────────
# 🔚 Transkript beenden
# Ab hier werden keine Konsolenausgaben mehr ins Logfile geschrieben.
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n═══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host " [Ende] Vorgang abgeschlossen – Transkript wird beendet." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan

Stop-Transcript
