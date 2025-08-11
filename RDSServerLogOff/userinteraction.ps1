# ─────────────────────────────────────────────────────────────────────────────
# 📜 Transkript starten – alles wird für die Nachwelt aufgezeichnet
# ─────────────────────────────────────────────────────────────────────────────

Start-Transcript -Path "C:\Temp\MicosAbmeldung\debuguser.log"


# ─────────────────────────────────────────────────────────────────────────────
# 💬 Benutzerinteraktion: Soll Micos geschlossen werden?
# ─────────────────────────────────────────────────────────────────────────────

Add-Type -AssemblyName System.Windows.Forms

$result = [System.Windows.Forms.MessageBox]::Show(
    "Micos schließen?",
    "Schließen",
    "OKCancel"
)


# ─────────────────────────────────────────────────────────────────────────────
# ✅ Wenn Benutzer "OK" klickt, geht’s los
# ─────────────────────────────────────────────────────────────────────────────

if ($result -eq "OK") {

    cls
    Write-Host "[Info] Benutzer hat OK gewählt – Skript beginnt." -ForegroundColor Cyan


    # ─────────────────────────────────────────────────────────────────────────
    # 📁 Pfad-Initialisierung
    # ─────────────────────────────────────────────────────────────────────────
    
    $path = "C:\Temp\MicosAbmeldung"
    $lockFilePath = "$path\lockfile.lock"
    $saveFilePath = "$path\user.json"


    # ─────────────────────────────────────────────────────────────────────────
    # 📂 Ordner & Savefile anlegen, falls nicht vorhanden
    # ─────────────────────────────────────────────────────────────────────────
    
    if ((Test-Path -Path $path) -eq $false) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
        Write-Host "[Info] Ordnerpfad erstellt: $path" -ForegroundColor Green

        New-Item -Path $saveFilePath -ItemType File -Force | Out-Null
        Write-Host "[Info] Savefile erstellt: $saveFilePath" -ForegroundColor Green
    }


    # ─────────────────────────────────────────────────────────────────────────
    # 🔒 Lockfile erstellen & Benutzername speichern
    # ─────────────────────────────────────────────────────────────────────────
    
    if ((Test-Path $lockFilePath) -eq $false) {
        New-Item -Path $lockFilePath -ItemType File -Force | Out-Null
        Write-Host "[Info] Lockfile erstellt: $lockFilePath" -ForegroundColor Yellow

        # 👤 Benutzername erfassen & als JSON speichern
        $user = [PSCustomObject]@{
            userName = $env:USERNAME
        }

        $json = $user | ConvertTo-Json
        $json | Set-Content -Path $saveFilePath
        Write-Host "[Info] Benutzername in Savefile gespeichert." -ForegroundColor Cyan

        Start-Sleep -Seconds 3

        # 🧹 Lockfile entfernen
        Remove-Item -Path $lockFilePath -Force
        Write-Host "[Fertig] Aufgabe abgeschlossen, Lockfile entfernt." -ForegroundColor Magenta
    }
}


# ─────────────────────────────────────────────────────────────────────────────
# 🔚 Transkript beenden
# ─────────────────────────────────────────────────────────────────────────────

Stop-Transcript
