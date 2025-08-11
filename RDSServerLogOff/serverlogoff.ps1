# ─────────────────────────────────────────────────────────────────────────────
# 🎥 Transkript starten – für sauberes Debugging
# ─────────────────────────────────────────────────────────────────────────────

Start-Transcript -Path "C:\Temp\MicosAbmeldung\debugkiller.log"


# ─────────────────────────────────────────────────────────────────────────────
# 💤 Kurzes Warten – lässt evtl. vorherige Prozesse Luft holen
# ─────────────────────────────────────────────────────────────────────────────

Start-Sleep -Seconds 3


# ─────────────────────────────────────────────────────────────────────────────
# 🧽 Konsole säubern für bessere Lesbarkeit
# ─────────────────────────────────────────────────────────────────────────────

cls


# ─────────────────────────────────────────────────────────────────────────────
# 📥 Benutzername aus JSON-Datei laden
# ─────────────────────────────────────────────────────────────────────────────

$saveFilePath = "C:\Temp\MicosAbmeldung\user.json"
$savefile     = Get-Content -Path $saveFilePath
$user         = $savefile | ConvertFrom-Json

Write-Host "[Info] Benutzer '$($user.userName)' aus Savefile geladen." -ForegroundColor Cyan


# ─────────────────────────────────────────────────────────────────────────────
# 💻 Liste der Zielserver definieren
# ─────────────────────────────────────────────────────────────────────────────

$remoteServer = @("BAS1-VM-RDS02", "BAS1-VM-RDS03")


# ─────────────────────────────────────────────────────────────────────────────
# 🔁 Remote-Abmeldung des Benutzers auf jedem Server
# ─────────────────────────────────────────────────────────────────────────────

foreach ($server in $remoteServer) {
    Write-Host "[Check] Prüfe auf Server: $server ..." -ForegroundColor DarkGray
    
    Invoke-Command -ComputerName $server -ScriptBlock {
        param($user)

        $succes 
        $queryOutput = query user
        $queryOutput
        $parsedUsers = @()

        foreach ($line in $queryOutput) {

            # Überspringt leere Zeilen
            if ($line.Trim() -eq "") { continue }

            # Entfernt ggf. führendes ">" und Leerzeichen
            $parts = $line -replace '^\s*>?', '' -split '\s{2,}'

            # Nur verarbeiten, wenn mind. 6 Spalten vorhanden
            if ($parts.Count -ge 6) {
                $parsedUsers += [PSCustomObject]@{
                    userName     = $parts[0]
                    session      = $parts[1]
                    id           = $parts[2]
                    status       = $parts[3]
                    idleTime     = $parts[4]
                    anmeldezeit  = $parts[5]
                }
            }
        }

        foreach ($userInfo in $parsedUsers) {
            if ($userInfo.userName -eq $user.userName) {
                Write-Host "[Abmeldung] Benutzer '$($userInfo.userName)' auf Session-ID $($userInfo.id)" -ForegroundColor Yellow
                try {
                    logoff $userInfo.id
                    Write-Host "[Erfolg] Benutzer abgemeldet." -ForegroundColor Green
                    $succes = $true
                } catch {
                    Write-Host "[Fehler] Abmeldung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
                }
            } 
        }
    Write-Host "Benutzer nicht gefunden." -ForegroundColor DarkGray 
    
    if ($success) {
        Write-Host "[Info] Vorgang abgeschlossen – keine weiteren Server notwendig." -ForegroundColor Cyan
        break
    }

    } -ArgumentList $user

    
}


# ─────────────────────────────────────────────────────────────────────────────
# 🔚 Transkript beenden
# ─────────────────────────────────────────────────────────────────────────────

Stop-Transcript
