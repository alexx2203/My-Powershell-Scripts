# Abmeldung von RDS-Benutzern – Scriptsammlung

Dieses Repository enthält drei PowerShell-Skripte, die zusammen eine geführte Abmeldung von Benutzersitzungen auf RDS-Servern ermöglichen. 
Die Lösung ist für den Helpdesk-Alltag gedacht: Benutzer starten eine kleine Oberfläche, bestätigen die Abmeldung, und im Hintergrund wird die aktive Sitzung gesucht und sauber beendet. 
Alle Schritte werden in Logdateien protokolliert.

---

## 🧩 Komponenten

1. **`userinteraction2.ps1`**  
   Startet eine kleine Benutzerinteraktion. Erzeugt ein Lockfile und speichert den aktuellen Benutzernamen in eine JSON-Datei.
2. **`Watcher.ps1`**  
   Überwacht einen Ordner per `FileSystemWatcher` und reagiert, wenn das Lockfile angelegt wird.
3. **`ServerAbmeldung.ps1`**  
   Liest den gespeicherten Benutzer, findet dessen Sitzung auf den RDS-Servern über den Connection Broker und führt die Abmeldung per `logoff <SessionId>` durch.

---

## 🔁 Ablauf

1. Benutzer startet **userinteraction2.ps1** (bei uns als RemoteApp veröffentlicht).
2. Das Skript legt im Arbeitsordner ein **`lockfile.lock`** sowie **`user.json`** mit dem aktuellen `ENV:USERNAME` an und beendet sich.
3. **Watcher.ps1** bemerkt das neue Lockfile und triggert die Serveraktion.
4. **ServerAbmeldung.ps1**:
   - liest `user.json`,
   - ermittelt über den RD Connection Broker (`...`) die **RDS-Zielserver**,
   - fragt Sessions per `quser.exe` auf jedem Zielserver ab,
   - vergleicht `userName` und führt bei Treffer `logoff <ID>` aus,
   - protokolliert und bricht nach erfolgreicher Abmeldung die Schleife ab.

---

## 📁 Standardpfade

- Basisordner: **`C:\Temp\MicosAbmeldung`**  
  Wird bei Bedarf angelegt.
- Dateien:
  - `lockfile.lock` – Trigger für den Watcher
  - `user.json` – enthält `{ "userName": "$env:USERNAME" }`
  - `debuguser.log` – Transcript der Benutzerinteraktion
  - `debugkiller.log` – Transcript der Abmeldelogik
  - (optional) `debugwatcher.log`

> Hinweis: Die vorliegenden Skripte schreiben bereits Transcripts für User- und Server-Teil. Falls gewünscht, kann im Watcher analog `Start-Transcript` ergänzt werden.

---

## 🛠 Voraussetzungen

- Windows Server mit **Remote Desktop Services** (Connection Broker vorhanden)
- Konto mit ausreichenden Rechten zum **Abmelden von Sitzungen** auf den RDS-Hosts
- Ausführungsrichtlinie erlaubt das Starten lokaler Skripte (`ExecutionPolicy` ≥ RemoteSigned/Bypass im Task)
- Schreibrechte auf `C:\Temp\MicosAbmeldung` für alle betroffenen Benutzer

---

## ⚙️ Konfiguration

### Connection Broker
In `ServerAbmeldung.ps1` ist der Broker aktuell so hinterlegt:
```powershell
Get-RDServer -ConnectionBroker ... -Role RDS-RD-SERVER
```


### Pfade
Die Skripte verwenden standardmäßig `C:\Temp\MicosAbmeldung`. 
Falls ein anderer Ordner gewünscht ist, in **`userinteraction2.ps1`** und **`Watcher.ps1`** anpassen.

---

## 🚀 Installation

1. Ordner anlegen und Skripte kopieren


2. **Geplante Aufgabe** für den Watcher erstellen (läuft als Dienstkonto mit höchsten Rechten)
  Entweder importieren oder erstellen (siehe unten)
   
🗓 Geplante Aufgabe: MicosAbmeldung (führt ServerAbmeldung.ps1 aus)

   	Zweck: Abmeldung des zuletzt ausgewählten Benutzers auf den RDS-Hosts. Diese Aufgabe wird vom Watcher bei Bedarf gestartet.

   	Basis-Konfiguration

   	Name: MicosAbmeldung

   	Trigger:
	bevorzugt kein Trigger (bedarfsgesteuert),
	alternativ Einmal (beliebiges Datum/Uhrzeit, nur damit die Aufgabe existiert).

	Aktion:
	Programm/Skript: powershell.exe
	Argumente:  -ExecutionPolicy Bypass -File "C:\Apps\ServerAbmeldung\ServerAbmeldung.ps1"
	Starten in: C:\Apps\ServerAbmeldung
	
	Benutzer/Konto:  Verwaltung\administrator
	Mit höchsten Privilegien ausführen

	Unabhängig von der Benutzeranmeldung ausführen

	Einstellungen:
	„Aufgabe bei Bedarf ausführen“ aktiv
	„Wenn bereits ausgeführt: Keine neue Instanz starten“ (oder „Neue Instanz nicht starten“)

🗓 Geplante Aufgabe: Watcher (überwacht Lockfile und startet „MicosAbmeldung“)

	Zweck: Überwacht den Ordner C:\Temp\MicosAbmeldung auf lockfile.lock und startet bei dessen Erstellung die Aufgabe „MicosAbmeldung“. Dient nur als Auslöser, führt keine 	Abmeldung selbst aus.

	Basis-Konfiguration

	Name: Watcher

	Trigger:
	Beim Systemstart
	zusätzlich „So schnell wie möglich nach einem verpassten Start ausführen“ aktivieren

	Aktion:
	Programm/Skript: powershell.exe

	Argumente:  -ExecutionPolicy Bypass -File " C:\Apps\ServerAbmeldung\Watcher.ps1"

	Starten in: C:\Apps\ServerAbmeldung

	Benutzer/Konto:  Verwaltung\administrator

	Mit höchsten Privilegien ausführen

	Unabhängig von der Benutzeranmeldung ausführen

	Bedingungen:
	„Nur starten, wenn Computer im Netzstrombetrieb“ deaktivieren


	Einstellungen:

	„Aufgabe bei Bedarf ausführen“ aktiv
	„Wenn die Aufgabe bereits ausgeführt wird: Keine neue Instanz starten“
	„Aufgabe beenden, wenn sie länger als … läuft“: deaktiviert (Watcher läuft dauerhaft)

   ```

3. **RemoteApp** für die Benutzerinteraktion veröffentlichen  
   - Wrapper-`BAT` oder direkt `powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Temp\MicosAbmeldung\userinteraction2.ps1"`
   - Als RemoteApp bereitstellen, damit Benutzer selbst starten können.

---

## 🧪 Funktionsprüfung

- **userinteraction**: `userinteraction2.ps1` lokal starten, danach prüfen, ob `lockfile.lock` und `user.json` erzeugt wurden.
- **Watcher**: `Watcher.ps1` manuell starten und prüfen, ob bei Lockfile-Erstellung die Reaktion erfolgt.
- **Server-Abmeldung**: Testbenutzer auf einem RDS anmelden, JSON händisch auf diesen Benutzer setzen, Skript starten und prüfen, ob die Sitzung abgemeldet wird.

---

## 🗂 Logging

- `C:\Temp\MicosAbmeldung\debuguser.log` – Ablauf Benutzerinteraktion
- `C:\Temp\MicosAbmeldung\debugkiller.log` – Ablauf Abmeldung auf den Servern
- Inhalte eignen sich für Fehleranalyse und Nachvollziehbarkeit. 

---


## 🧹 Deinstallation

1. Geplante Tasks entfernen  
   ```
2. Ordner löschen  
   ```

---

## ❗ Troubleshooting

- **`Get-RDServer` schlägt fehl**: RD-Management-Module installieren, Broker-Name prüfen, Berechtigungen.
- **Session wird nicht gefunden**: Prüfen, ob `user.json` den korrekten `userName` enthält. Ausgabe von `quser.exe` im Log ansehen.
- **Kein Log**: ExecutionPolicy und Transcripts prüfen, Zielpfad existiert? Schreibrechte vorhanden?
- **Mehrere RDS-Hosts**: Schleife bricht nach erster erfolgreichen Abmeldung ab. Verhalten ist beabsichtigt.

---
