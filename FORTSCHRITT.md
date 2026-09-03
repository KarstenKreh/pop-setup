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

- [ ] Tailscale angemeldet (`sudo tailscale up`)
- [ ] `gh auth login`, `claude` einmal gestartet
- [ ] COSMIC: Akzentfarbe, Dock, Workspaces (Coding tiled, Rest floating)
- [ ] 1Password angemeldet
- [ ] Obsidian-Vault und Proton Drive (rclone) angebunden

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
