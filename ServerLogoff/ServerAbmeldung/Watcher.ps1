
# ─────────────────────────────────────────────────────────────────────────────────────────────
# 🧹 Vorherige Event-Registrierung bereinigen, falls noch vorhanden
# ─────────────────────────────────────────────────────────────────────────────────────────────

try {
    Unregister-Event -SourceIdentifier "MicosEvent" -ErrorAction SilentlyContinue
    Write-Host "[Info] Event 'MicosEvent' wurde abgemeldet (sofern vorhanden)." -ForegroundColor Cyan
} catch {
    Write-Host "[Warnung] Konnte vorherigen Event nicht abmelden." -ForegroundColor Yellow
}


# ─────────────────────────────────────────────────────────────────────────────────────────────
# 👁️ Dateiüberwachung vorbereiten
# ─────────────────────────────────────────────────────────────────────────────────────────────

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Temp\MicosAbmeldung"           # Pfad, der überwacht werden soll
$watcher.Filter = "lockfile.lock"                  # Nur diese Datei wird überwacht
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName
$watcher.EnableRaisingEvents = $true

Write-Host "[Info] Überwachung gestartet auf: $($watcher.Path)\$($watcher.Filter)" -ForegroundColor Green


# ─────────────────────────────────────────────────────────────────────────────────────────────
# 📦 Event registrieren: Wenn Datei erstellt wird → Task starten
# ─────────────────────────────────────────────────────────────────────────────────────────────

Register-ObjectEvent -InputObject $watcher `
                     -EventName "Created" `
                     -SourceIdentifier "MicosEvent" `
                     -Action {
    Write-Host "[Trigger] Datei 'lockfile.lock' wurde erstellt – Task wird gestartet!" -ForegroundColor Magenta
    Start-ScheduledTask -TaskPath "\MicosAbmeldung\" -TaskName "MicosAbmeldung"
    
    # Logfile für eigene Trigger-Nachverfolgung
    #Add-Content -Path "C:\Temp\MicosAbmeldung\trigger.log" `
    #            -Value "$(Get-Date): Task ausgelöst"
}


# ─────────────────────────────────────────────────────────────────────────────────────────────
# 💤 Dauerschleife – Skript bleibt aktiv und wartet auf Trigger
# ─────────────────────────────────────────────────────────────────────────────────────────────

Write-Host "[Warte] Wache über lockfile.lock … (drücke STRG+C zum Beenden)" -ForegroundColor DarkGray
while ($true) {
    Start-Sleep -Seconds 1
}

