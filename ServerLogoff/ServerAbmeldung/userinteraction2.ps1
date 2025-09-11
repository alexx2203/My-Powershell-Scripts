# ─────────────────────────────────────────────────────────────────────────────
# 📜 Transkript starten – alles wird für die Nachwelt aufgezeichnet
# ─────────────────────────────────────────────────────────────────────────────
Start-Transcript -Path "C:\Temp\MicosAbmeldung\debuguser.log"
# Konsole säubern, damit die Ausgaben übersichtlich bleiben
cls
Write-Host "Aufzeichnung gestartet"


# ─────────────────────────────────────────────────────────────────────────────
# 💬 Benutzerinteraktion: Soll der Uservom Server abgemeldet werden?
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# 📦 Assemblies für WPF laden
# ─────────────────────────────────────────────────────────────────────────────
# WPF benötigt diese Bibliotheken. Ohne sie lässt sich das XAML-Fenster nicht bauen.
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Drawing    # Für das Standard-Warnicon


# ─────────────────────────────────────────────────────────────────────────────
# 📝 Texte für Dialog definieren
# ─────────────────────────────────────────────────────────────────────────────
$title   = "Abmeldung bestätigen" # Fenstertitel
$message = @"
Sie melden sich jetzt vom Server ab.
Dabei werden ggf. auch andere Work Ressources geschlossen.
Bitte speichern Sie Ihre Arbeit vorher ab, um Datenverlust zu vermeiden.
"@.Trim()

# Schriftgröße zentral definiert (einfach anpassbar)
$BaseFontSize = 16

# ─────────────────────────────────────────────────────────────────────────────
# 🧱 XAML = "Fensterbauplan"
# ─────────────────────────────────────────────────────────────────────────────
# Hier wird Layout und Aussehen beschrieben.
# Wichtig: Keine modernen Eigenschaften wie HeadingLevel, da ältere Systeme diese nicht kennen.
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$title"
        Height="260" Width="540"
        MinWidth="440"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        WindowStyle="SingleBorderWindow"
        FontFamily="Segoe UI"
        UseLayoutRounding="True"
        Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}"
        Foreground="{DynamicResource {x:Static SystemColors.WindowTextBrushKey}}">

    <Window.Resources>
        <!-- Außenabstand -->
        <Thickness x:Key="OuterMargin">16</Thickness>
        <!-- Einheitliche Buttonhöhe -->
        <x:Double  x:Key="ButtonHeight">36</x:Double>
    </Window.Resources>

    <Grid Margin="{StaticResource OuterMargin}">
        <!-- Layout: 3 Zeilen (Titel, Nachricht, Buttons) und 2 Spalten (Icon, Text) -->
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="56"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Warn-Icon links oben -->
        <Image x:Name="WarnIcon"
               Grid.Row="0" Grid.Column="0" Grid.RowSpan="2"
               Width="40" Height="40" Margin="0,0,12,0"
               VerticalAlignment="Top" Stretch="Uniform" />

        <!-- Überschrift = Fenstertitel -->
        <TextBlock Grid.Row="0" Grid.Column="1"
                   FontSize="18" FontWeight="Bold"
                   Text="{Binding Title, RelativeSource={RelativeSource AncestorType=Window}}"
                   Margin="0,0,0,8" />

        <!-- Nachrichtentext, umbrochen -->
        <TextBlock x:Name="Message"
                   Grid.Row="1" Grid.Column="1"
                   TextWrapping="Wrap"
                   FontSize="$($BaseFontSize)"
                   LineHeight="$([int]([double]$BaseFontSize * 1.4))" />

        <!-- Buttons unten rechts -->
        <StackPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2"
                    Orientation="Horizontal"
                    HorizontalAlignment="Right"
                    Margin="0,16,0,0">
            <Button x:Name="CancelButton"
                    Content="_Abbrechen"
                    Height="{StaticResource ButtonHeight}"
                    MinWidth="120"
                    Margin="0,0,12,0"
                    IsCancel="True"
                    TabIndex="1" />
            <Button x:Name="OkButton"
                    Content="_OK"
                    Height="{StaticResource ButtonHeight}"
                    MinWidth="120"
                    IsDefault="True"
                    TabIndex="0" />
        </StackPanel>
    </Grid>
</Window>
"@


# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Fenster aus XAML erzeugen und füllen
# ─────────────────────────────────────────────────────────────────────────────
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Nachrichtentext einsetzen
$window.FindName("Message").Text = $message

# System-Warnicon laden und setzen
$imgCtrl = $window.FindName("WarnIcon")
$hIcon   = [System.Drawing.SystemIcons]::Warning.Handle
$bmpSrc  = [System.Windows.Interop.Imaging]::CreateBitmapSourceFromHIcon(
              $hIcon,
              [System.Windows.Int32Rect]::Empty,
              [System.Windows.Media.Imaging.BitmapSizeOptions]::FromEmptyOptions()
          )
$imgCtrl.Source = $bmpSrc

# Buttons verbinden mit Logik
$okBtn     = $window.FindName("OkButton")
$cancelBtn = $window.FindName("CancelButton")

$okBtn.Add_Click({ $window.DialogResult = $true;  $window.Close() })
$cancelBtn.Add_Click({ $window.DialogResult = $false; $window.Close() })

# Beim Rendern sofort Fokus auf "OK" setzen
$window.Add_ContentRendered({ $okBtn.Focus() | Out-Null })


# ─────────────────────────────────────────────────────────────────────────────
# 🎭 Fenster anzeigen, Ergebnis auswerten
# ─────────────────────────────────────────────────────────────────────────────
$result = $window.ShowDialog()

# Wenn Abbrechen oder Schließen (X): nichts tun, Skript beenden
if (-not $result) {
    Write-Host "[Info] $($env:USERNAME) hat abgebrochen: Es passiert nichts." -ForegroundColor Cyan
    Write-Host "Aufzeichnung beendet"
    Stop-Transcript 
    } 
    
# ─────────────────────────────────────────────────────────────────────────────
# ✅ Wenn Benutzer "OK" klickt, geht’s los
# ─────────────────────────────────────────────────────────────────────────────
if ($result -eq "OK") {
    
    Write-Host "[Info] $($env:USERNAME) hat OK gewählt." -ForegroundColor Cyan

    # ─────────────────────────────────────────────────────────────────────────
    # 📁 Pfad-Initialisierung
    # ─────────────────────────────────────────────────────────────────────────
    $path         = "C:\Temp\MicosAbmeldung"
    $lockFilePath = "$path\lockfile.lock"
    $saveFilePath = "$path\user.json"

    # ─────────────────────────────────────────────────────────────────────────
    # 📂 Ordner & Savefile anlegen, falls nicht vorhanden
    # ─────────────────────────────────────────────────────────────────────────
    if ((Test-Path -Path $path) -eq $false) {
        # Ordner erstellen
        New-Item -Path $path -ItemType Directory -Force | Out-Null
        Write-Host "[Info] Ordnerpfad erstellt: $path" -ForegroundColor Green

        # Savefile erstellen
        New-Item -Path $saveFilePath -ItemType File -Force | Out-Null
        Write-Host "[Info] Savefile erstellt: $saveFilePath" -ForegroundColor Green
    }

    # ─────────────────────────────────────────────────────────────────────────
    # 🔒 Lockfile erstellen & Benutzername speichern
    # ─────────────────────────────────────────────────────────────────────────
    if ((Test-Path $lockFilePath) -eq $false) {
        # Lockfile anlegen
        New-Item -Path $lockFilePath -ItemType File -Force | Out-Null
        Write-Host "[Info] Lockfile erstellt: $lockFilePath" -ForegroundColor Yellow

        # Benutzername erfassen & in JSON-Datei speichern
        $user = [PSCustomObject]@{
            userName = $env:USERNAME
        }

        $json = $user | ConvertTo-Json
        $json | Set-Content -Path $saveFilePath
        Write-Host "[Info] Benutzername in Savefile gespeichert." -ForegroundColor Cyan

        # Kurze Pause
        Start-Sleep -Seconds 1

        # Lockfile wieder entfernen
        Remove-Item -Path $lockFilePath -Force
        Write-Host "[Fertig] Aufgabe abgeschlossen, Lockfile entfernt." -ForegroundColor Green
    }
    # ─────────────────────────────────────────────────────────────────────────────
    # 🔚 Transkript beenden
    # ─────────────────────────────────────────────────────────────────────────────
  
    Stop-Transcript

}