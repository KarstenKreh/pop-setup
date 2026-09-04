# Fortschritt Pop!_OS-Umstieg

Laptop: i9-14900HX, RTX 4070 Laptop, 32 GB, eine 2-TB-NVMe (Crucial P310).
Plan: Dual-Boot, Windows 11 Home bleibt verkleinert als Notnagel, Pop!_OS 24.04 NVIDIA wird Hauptsystem.

Für den Agenten: Diese Datei ist die Wahrheit über den Stand. Zuerst hier lesen, dann weitermachen. Erledigtes abhaken, Datum dazuschreiben.

## Phase 1: Vorbereitung in Windows (macht der Agent)

- [x] Hardware und Platte erfasst (2026-09-02)
- [x] Repo angelegt, Setup-Skript geschrieben (2026-09-02)
- [x] ISO geladen und Prüfsumme geprüft (`pop-os_24.04_amd64_nvidia_27.iso`, SHA256 `2c68c26e…`) (2026-09-02)
- [x] Diagnose: Secure Boot, BitLocker, minimale Größe von C: (2026-09-02)
- [x] Ruhezustand und Schnellstart in Windows aus (2026-09-02)
- [x] C: verkleinert, freier Platz für Linux (2026-09-02)
- [x] USB-Stick mit ISO beschrieben und verifiziert (2026-09-02)

## Phase 2: Installation (macht Karsten, siehe INSTALL.md)

- [x] Secure Boot im BIOS aus (2026-09-02)
- [x] Von USB gebootet, Pop!_OS installiert (Custom, in den freien Platz) (2026-09-02)
- [x] Erster Start in Pop!_OS, WLAN verbunden (2026-09-02)

## Phase 3: Einrichtung in Pop!_OS (Skript, Agent übernimmt wieder)

Skriptschritte, das Skript hakt sie selbst ab:

- [x] nvidia_check
- [x] apt_base
- [x] timeshift_config
- [x] snapshot_before (Timeshift-Bug, nachgeholt 2026-09-03)
- [x] system_upgrade
- [x] firmware
- [x] flatpak
- [x] onepassword
- [x] github_cli
- [x] node_fnm
- [x] claude_code
- [x] docker
- [x] nvidia_container_toolkit
- [x] tailscale
- [x] session_path
- [x] t3code
- [x] cosmic_dark
- [x] snapshot_after (nachgeholt 2026-09-03)

Von Hand danach (je zwei Klicks, siehe INSTALL.md unten):

- [x] Tailscale angemeldet (2026-09-03, Geraet `pop-os`, 100.80.97.26)
- [ ] `gh auth login`, `claude` einmal gestartet
- [ ] COSMIC: Akzentfarbe, Dock, Workspaces (Coding tiled, Rest floating)
- [ ] 1Password angemeldet
- [x] Obsidian-Vault nach ~/Documents/Obsidian kopiert (2026-09-03)
- [x] Repos nach ~/Repositories kopiert, 40 GB ohne node_modules (2026-09-03)
- [x] .ssh, ~/.claude (CLAUDE.md, Hook, Skript, settings), ~/.codex, ~/.gemini von Windows uebernommen (2026-09-03)
- [x] Proton Drive und SharePoint (DK Tech, memozero, Safina AI) per rclone 1.75 eingehaengt, systemd-user-Units rclone-*.service, Skripte cloud-login.sh / cloud-mount.sh (2026-09-03)
- [ ] Agenten-Regeln aus ~/Proton Drive/agent-sync (RULES.md, Ordner heisst nicht mehr claude-sync) auf Linux verteilen; die .ps1-Skripte dort laufen hier nicht
- [ ] Optional: smart-change-Sites (FinTwin, DINspektor, ...) einhaengen, Login liegt als Remote sp-smartchange-onedrive vor
- [ ] LM-Studio- und memozero-Modelle (73 GB + 32 GB) von /mnt/win holen, wenn gewuenscht

## Phase 4: Feineinstellungen (desktop.sh, Agent)

Alles aus dem Ordner `desktop/`, Skript hakt selbst ab:

- [x] apt_desktop
- [x] environment
- [x] nightlight
- [x] show_desktop
- [x] keytap
- [x] op_fill
- [x] audio
- [x] cosmic
- [x] onepassword_desktop
- [x] wispr_flow
- [x] wispr_prefs
- [x] monkey_mode

Von Hand danach:

- [x] Wispr Flow angemeldet (2026-09-03)
- [x] 1Password: Systemauthentifizierung und CLI-Integration eingeschaltet, SSH-Agent an (2026-09-03)
- [x] 1Password-Flatpak entfernt, nur noch das .deb (2026-09-03)
- [x] Monkey Mode: tagesliste.py pfadunabhängig (`Path.home()`), systemd-Timer statt Windows-Aufgabe (2026-09-03)
- [ ] `gh auth login` mit Scope `project`, sonst läuft Monkey Mode nur aus dem Cache

## Stand 2026-09-03, nachmittags

Auf diesem Rechner ist alles aus Phase 4 bereits von Hand eingerichtet; `desktop.sh` ist die
Konserve davon für den nächsten Rechner oder eine Neuinstallation. Reihenfolge dann:
`setup.sh`, abmelden, `desktop.sh`, abmelden, Wispr Flow und 1Password anmelden, `desktop.sh`
noch einmal (setzt die Wispr-Einstellungen, die erst nach dem Anmelden existieren).

Erkenntnisse, die Zeit sparen:

- COSMIC hat kein Nachtlicht und exportiert kein Gamma-Protokoll; gammastep/wlsunset gehen nicht.
  Deshalb das eigene Overlay in `desktop/nightlight`.
- Wispr Flow im nativen Wayland-Modus zeigt die Leiste als normales schwarzes Fenster. XWayland
  (`--ozone-platform=x11`) behebt das. Leiste rechts (`statusDockEdge`) und versteckt
  (`hideFlowBarPermanently`) sind Werte in der Config, in der App gibt es dafür keinen Schalter.
- Bluetooth-Kopfhörer schalten beim Aufnehmen in den Telefon-Modus und reißen die Musik ab.
  Lösung: Laptop-Mikro als Standard, `bluetooth.autoswitch-to-headset-profile = false`.
- 1Password füllt unter Linux keine Desktop-Programme aus. `op-fill` macht das über die
  CLI-Integration plus `keytap`. `op whoami` meldet trotzdem "not signed in", das ist normal.
- Aus einer Claude-Code-Shell heraus Electron-Apps immer mit `env -u ELECTRON_RUN_AS_NODE`
  starten, sonst brechen sie mit "bad option" ab.

## Entschieden am 2026-09-02

- Windows bleibt mit ca. 250 GB als Notnagel, kein gemeinsamer Datenbereich.
- Nichts doppelt: Proton Drive und SharePoint unter Linux per rclone bei Bedarf, lokale Proton-Kopie in Windows (113 GB) wird entfernt, OneDrive nur Platzhalter.
- Repos wohnen im Linux-Home, Obsidian klein auf beiden Seiten.
- Partitionen neu: POP_EFI 1 GB, POP_RECOVERY 4 GB, POP_ROOT Rest verschluesselt.

## Notizen

- Windows-Diagnose steht in `diag.txt` (nicht im Repo, liegt lokal in `C:\Users\karst\pop-setup\`).

## Stand 2026-09-03

Skript einmal komplett durchgelaufen, Exit 0. Alle 16 Schritte plus `session_path` und `t3code` erledigt.
Geprueft: NVIDIA 595.84, `nvidia-smi` laeuft auch im Docker-Container (CUDA 13.2), Node v24.20.0,
Docker 29.7.2, gh 2.99.0, Tailscale 1.102.3 (noch abgemeldet), 14 Flatpaks installiert.

Drei Korrekturen am Skript, die der erste Lauf erzwungen hat:

- **Flatpak auf `--user`**: `remote-add`/`install` ohne `--user` oeffnet einen polkit-Passwortdialog und
  blockiert damit jeden unbeaufsichtigten Lauf. Die Remotes auf diesem Rechner sind ohnehin User-Remotes.
- **`--tags O` bei Timeshift entfernt**: Timeshift 24.01.1 lehnt den Wert ab, obwohl die eigene Hilfe ihn
  so dokumentiert. `O` ist der Default, das Flag war entbehrlich. Vorher scheiterte *jeder* Snapshot.
- **`session_path`**: COSMIC liest weder `.bashrc` noch `.profile`, die grafische Session hatte
  `~/.local/bin` nicht im PATH. Aus dem Launcher gestartete Programme fanden `claude` deshalb nicht.
  Jetzt ueber `~/.config/environment.d/10-local-bin.conf` gesetzt.

Bekannt, aber nicht behoben: `/` liegt unverschluesselt auf `nvme0n1p6`. Der Plan sah LUKS fuer POP_ROOT
vor; das liesse sich nur mit einer Neuinstallation nachholen.

Icons im Dock fehlen fuer alles, was nach dem Start von `cosmic-panel` installiert wurde. Kein Defekt,
die Dateien und Caches stimmen: COSMIC liest die Zuordnung nur beim Start ein. Ab- und Anmelden loest es.

## COSMIC: Symbole und Fensterzuordnung (2026-09-03)

Zwei Fallen, die zusammen einen halben Vormittag gekostet haben.

**1. COSMIC liest Programme und Symbole nur beim Start ein.** Alles, was nach dem Anmelden installiert wird, erscheint in Dock, Launcher und App-Bibliothek mit Zahnrad-Platzhalter oder gar nicht. Betroffen sind drei getrennte Prozesse, die einzeln neu starten muessen: `cosmic-panel` (Dock), `cosmic-launcher` (Suche mit Super+/) und `cosmic-app-list` (die Symbolreihe im Dock). Der zuverlaessige Weg ist ab- und anmelden. Wer die Prozesse von Hand beendet, muss aufpassen: `cosmic-session` startet sie selbst nach, aber teils erst nach ueber zwei Minuten. Wer zu frueh selbst eines startet, hat zwei Leisten uebereinander.

**2. Fenster werden ueber `app_id` einer Programmdatei zugeordnet.** Passt nichts, zeigt COSMIC ein Zahnrad, als Beschriftung den letzten Punkt-Abschnitt der `app_id`, und Anheften ans Dock schlaegt fehl: Der Eintrag verschwindet sofort wieder. Die Zuordnung laeuft ueber den Dateinamen der `.desktop`-Datei oder ueber `StartupWMClass`.

Brave im App-Modus meldet sich als `brave-outlook.office.com__mail_-Default` an, mit `brave-` am Anfang, nicht mit dem sonst ueblichen `chrome-`. `--class=` hilft nicht, Chromium ueberschreibt die Klasse bei `--app`-Fenstern immer selbst.

**Nicht raten, nachsehen.** `~/.local/bin/lswt` listet alle offenen Fenster mit ihrer echten `app_id`. Ein kleiner Eigenbau ueber das `ext_foreign_toplevel_list_v1`-Protokoll, weil `wlrctl` und `xdotool` unter COSMIC nicht weiterhelfen. Bei einem neuen Rechner mit uebertragen.


## Mail: vier Outlook-Fenster, eines je Mandant (2026-09-03, ersetzt die Abschnitte oben)

Entschieden: Outlook im Web, pro Microsoft-Mandant ein eigenes Brave-Fenster mit eigenem Brave-Profil. Ohne getrennte Profile wirft die Anmeldung eines Mandanten die anderen raus.

**Warum kein Mail-Programm.** In allen Mandanten sperren die aktiven Sicherheitsstandards den SMTP-Versand durch fremde Programme. Thunderbird und Mailspring scheiterten daran. Evolution aus Flathub mit dem Kontotyp "Microsoft 365" funktionierte technisch komplett (Empfangen und Senden ueber Microsofts Graph-Schnittstelle, alle Postfaecher in einem Fenster), wurde aber wegen der altbackenen Oberflaeche wieder verworfen und restlos entfernt. Die Ubuntu-Version von Evolution (3.52) ist ausserdem defekt: sie schreibt bei jedem Start rund 300 Mails erneut als "gelesen" zurueck und blockiert dabei das Fenster.

**Offen geblieben.** Vermutlich ist nicht die Sicherheitsstandard-Einstellung selbst das Problem, sondern der separate Schalter "SMTP AUTH", den Microsoft in neuen Mandanten pro Postfach abschaltet. Den koennte man einzeln wieder anschalten, ohne die Zwei-Faktor-Anmeldung anzutasten. Dann liefe auch ein huebscheres Mail-Programm. Nicht geprueft.

**Welche Domain in welchem Mandanten liegt.** Es sind nur drei Mandanten, nicht vier: smart-change.app und fintwin.app teilen sich einen (b1c07404-a6c6-4367-b25f-fdb34beb564a), safina.ai und memozero.io einen zweiten (f1a63b8d-a074-4159-897f-8917782f5030), 8-reasons.com steht allein (37e63899-a650-42b7-b9fb-98606a9289d1). Nachpruefbar ohne Anmeldung mit `curl -s https://login.microsoftonline.com/<domain>/v2.0/.well-known/openid-configuration`.

**Eingerichtet.** Drei Eintraege in `~/.local/share/applications/`: `outlook-smartchange.desktop`, `outlook-safina.desktop`, `outlook-8reasons.desktop`. Genutzt werden Smart Change und Safina; 8 Reasons steht als Reserve im Menue. Muster:

```
[Desktop Entry]
Type=Application
Name=Outlook Safina
GenericName=E-Mail
Exec=flatpak run com.brave.Browser --profile-directory=Outlook-safina --app=https://outlook.office.com/mail/ %U
Icon=outlook-web
Terminal=false
Categories=Network;Email;
StartupWMClass=brave-outlook.office.com__mail_-Outlook-safina
StartupNotify=true
```

Symbol: `~/.local/share/icons/hicolor/scalable/apps/outlook-web.svg`. Nach dem Anlegen einmal ab- und anmelden, sonst kennt COSMIC die Eintraege nicht.

**Geteilte Postfaecher.** Im Safina-Fenster: info@safina.ai, billing@safina.ai, info@memozero.io. Im Smart-Change-Fenster: service@fintwin.app. Einhaengen per Rechtsklick auf den eigenen Namen in der Ordnerliste, "Freigegebenen Ordner hinzufuegen". Ueber Mandantengrenzen hinweg geht das nicht, deshalb die getrennten Fenster.

**Datenreste.** Evolution ist vollstaendig entfernt. Die apt-Pakete der kaputten Version sind noch installiert, Entfernen braucht das sudo-Passwort: `sudo apt remove evolution evolution-ews evolution-plugins evolution-plugin-bogofilter evolution-plugin-pstimport`. Ausserdem liegen noch `~/.var/app/org.mozilla.thunderbird` (5,8 GB) und `~/.var/app/com.getmailspring.Mailspring` (336 MB) herum.
