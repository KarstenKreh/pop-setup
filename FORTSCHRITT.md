# Fortschritt Pop!_OS-Umstieg

Laptop: i9-14900HX, RTX 4070 Laptop, 32 GB, eine 2-TB-NVMe (Crucial P310).
Plan: Dual-Boot, Windows 11 Home bleibt verkleinert als Notnagel, Pop!_OS 24.04 NVIDIA wird Hauptsystem.

Für den Agenten: Diese Datei ist die Wahrheit über den Stand. Zuerst hier lesen, dann weitermachen. Erledigtes abhaken, Datum dazuschreiben.

## Phase 1: Vorbereitung in Windows (macht der Agent)

- [x] Hardware und Platte erfasst (2026-09-02)
- [x] Repo angelegt, Setup-Skript geschrieben (2026-09-02)
- [ ] ISO geladen und Prüfsumme geprüft (`pop-os_24.04_amd64_nvidia_27.iso`, SHA256 `2c68c26e…`)
- [ ] Diagnose: Secure Boot, BitLocker, minimale Größe von C:
- [ ] Ruhezustand und Schnellstart in Windows aus
- [ ] C: verkleinert, freier Platz für Linux
- [ ] USB-Stick mit ISO beschrieben und verifiziert

## Phase 2: Installation (macht Karsten, siehe INSTALL.md)

- [ ] Secure Boot im BIOS aus
- [ ] Von USB gebootet, Pop!_OS installiert (Custom, in den freien Platz)
- [ ] Erster Start in Pop!_OS, WLAN verbunden

## Phase 3: Einrichtung in Pop!_OS (Skript, Agent übernimmt wieder)

Skriptschritte, das Skript hakt sie selbst ab:

- [ ] nvidia_check
- [ ] apt_base
- [ ] timeshift_config
- [ ] snapshot_before
- [ ] system_upgrade
- [ ] firmware
- [ ] flatpak
- [ ] onepassword
- [ ] github_cli
- [ ] node_fnm
- [ ] claude_code
- [ ] docker
- [ ] nvidia_container_toolkit
- [ ] tailscale
- [ ] cosmic_dark
- [ ] snapshot_after

Von Hand danach (je zwei Klicks, siehe INSTALL.md unten):

- [ ] Tailscale angemeldet (`sudo tailscale up`)
- [ ] `gh auth login`, `claude` einmal gestartet
- [ ] COSMIC: Akzentfarbe, Dock, Workspaces (Coding tiled, Rest floating)
- [ ] 1Password angemeldet
- [ ] Obsidian-Vault und Proton Drive (rclone) angebunden

## Notizen

- Windows-Diagnose steht in `diag.txt` (nicht im Repo, liegt lokal in `C:\Users\karst\pop-setup\`).
