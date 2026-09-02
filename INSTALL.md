# Installation Pop!_OS 24.04 (Dual-Boot neben Windows)

Das ist der Teil, den Karsten selbst am Gerät macht. Der Agent ist währenddessen nicht erreichbar. Nach Schritt 4 geht es im Repo weiter.

## 1. BIOS: Secure Boot aus

Laptop neu starten, beim Start `F2` oder `Entf` drücken (bei diesem Gerät eventuell `F7` für das Bootmenü). Unter Security oder Boot den Punkt `Secure Boot` auf `Disabled` stellen. Speichern mit `F10`. Pop!_OS startet sonst nicht vom Stick.

Falls Windows danach nach einem BitLocker-Wiederherstellungsschlüssel fragt: den gibt es unter https://account.microsoft.com/devices/recoverykey. Der Agent hat vorher in `diag.txt` geprüft, ob BitLocker überhaupt an ist.

## 2. Vom USB-Stick booten

Stick stecken lassen, neu starten, Bootmenü öffnen (`F7`, `F12` oder `F11`, je nach BIOS) und den Eintrag mit `UEFI` und dem USB-Namen wählen. Es erscheint der Pop!_OS-Installer.

## 3. Installer

1. Sprache Deutsch, Tastatur Deutsch, Zeitzone Berlin.
2. Bei der Frage zur Installationsart **nicht** "Clean Install" wählen, das würde Windows löschen. Stattdessen **Custom (Advanced)** oder **Benutzerdefiniert**.
3. Im Partitionsbild die 2-TB-NVMe wählen. Dort liegen vorbereitet:
   - Windows-Partitionen (nicht anfassen): EFI 100 MB, Reserved, Windows C:, Recovery
   - **Eine neue Partition `POP_EFI`, 1 GB, FAT32**: anklicken, "Use partition" an, "Format" an, Filesystem `fat32`, Custom mount point `/boot/efi`
   - **Eine neue Partition `POP_ROOT`, der große Rest**: anklicken, "Use partition" an, "Format" an, Filesystem `ext4`, Mount `/`, und **Encrypt** anhaken, Passwort setzen (das ist die Festplattenverschlüsselung, jeden Start abfragen lassen ist gewollt)
   - Optional eine dritte Partition `POP_RECOVERY`, 4 GB, FAT32, Mount `/recovery`. Nur wenn der Agent sie angelegt hat.
4. Installieren, Benutzer `karsten` anlegen, Passwort setzen, Neustart, Stick abziehen.

## 4. Erster Start in Pop!_OS

1. Anmelden, WLAN oben rechts verbinden.
2. Terminal öffnen (`Super` drücken, "Terminal" tippen).
3. Genau diese drei Zeilen tippen:

```
git clone https://github.com/KarstenKreh/pop-setup.git ~/pop-setup
cd ~/pop-setup
bash setup.sh
```

Das Skript fragt am Anfang das Passwort für `sudo` ab und läuft dann 20 bis 30 Minuten. Bricht es ab, einfach `bash setup.sh` nochmal starten, fertige Schritte überspringt es.

4. Danach einmal abmelden und wieder anmelden (wegen Docker).
5. Im Terminal `claude` starten, im Repo-Ordner `~/pop-setup`. Der Agent liest `FORTSCHRITT.md` und macht weiter.

## Klicks, die keine Automatik übernimmt

- **Tailscale**: `sudo tailscale up`, den Link im Browser öffnen, anmelden.
- **GitHub**: `gh auth login`, Browser, fertig.
- **COSMIC-Look**: Einstellungen, Desktop, Erscheinungsbild: Dunkel ist schon gesetzt, Akzentfarbe wählen. Unter Panel/Dock das Dock an. Unter Fenster-Management Tiling aus, dann auf dem Coding-Workspace mit `Super+Y` Tiling nur dort an.
- **1Password**: App starten, anmelden, Browser-Erweiterung.
