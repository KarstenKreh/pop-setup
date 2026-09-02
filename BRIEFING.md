# Briefing für den Agenten unter Pop!_OS

Erstellt am 2026-09-02 aus dem echten Windows-Bestand. Ziel: Karsten soll nach `setup.sh` sofort arbeiten können, ohne dass das System mit Zeug zugemüllt wird. Schlank halten, nur was hier steht.

## Wer Karsten ist

Tech Designer, kein Terminal-Alltag. Arbeitet mit vielen KI-Agenten (Claude Code, T3 Code, Cursor, Codex, Gemini). Denkt in Abläufen, nicht in Implementierungsdetails. Antworten kurz, einfache Sprache, ein Schritt auf einmal. Seine Agenten-Regeln liegen in Proton Drive unter `claude-sync/AGENTS.md` und werden von dort nach `~/.claude/CLAUDE.md` kopiert. Das funktioniert erst, wenn Proton Drive per rclone eingebunden ist.

## Was er täglich nutzt (Windows, Stand September 2026)

| Bereich | Windows | Unter Linux |
|---|---|---|
| Browser | Brave | Flatpak `com.brave.Browser` |
| Notizen | Obsidian, Vault `Documents/Obsidian` mit 5 Untervaults, Plugin smart-connections | Flatpak `md.obsidian.Obsidian`, Vault von der Windows-Partition kopieren |
| Passwörter, SSH | 1Password mit SSH-Agent | 1Password apt-Paket, SSH-Agent in den Einstellungen einschalten |
| Coding | T3 Code, Cursor, Claude Code (npm global), fnm, Node 25, pnpm 10, Python 3.13 | Claude Code nativ, fnm mit Node LTS, pnpm über corepack, Cursor als AppImage nur wenn Karsten fragt, T3 Code prüfen ob es Linux gibt |
| Container | Docker Desktop | Docker Engine plus NVIDIA Container Toolkit (macht setup.sh) |
| Diktat | Wispr Flow | Gibt es nicht für Linux. Alternative erst besprechen, nichts vorauseilend installieren |
| Mail, Cloud | Proton Mail, Proton Drive, Proton Pass, Proton VPN | Proton Mail Flatpak `me.proton.Mail`, Proton Drive über rclone (Remote-Typ `protondrive`), Pass als Browser-Erweiterung |
| Chat | Signal, Slack, Telegram, Discord, Zoom | Flatpaks `org.signal.Signal`, `com.slack.Slack`, `org.telegram.desktop`, `com.discordapp.Discord`, `us.zoom.Zoom` |
| Design | Figma (Desktop), Framer, Affinity | Figma und Framer im Browser, Affinity gibt es nicht für Linux |
| Kreativ | Blender, Audacity | Flatpaks `org.blender.Blender`, `org.audacityteam.Audacity` |
| Musik | TIDAL, Spotify | Im Browser, keine App nötig |
| Netz | Tailscale (Tailnet mit dev-ops, prod-ops, memozero-license-01, prod-support-chatbot) | Tailscale apt (macht setup.sh), `sudo tailscale up` |
| Server | WinSCP, hcloud, AWS CLI, Twilio CLI | `hcloud` und `awscli` nur bei Bedarf, Twilio über npx |
| KI lokal | LM Studio mit 72 GB Modellen, memozero mit 54 GB Modellen | Modelle von der Windows-Partition kopieren, nicht neu laden |
| Spiele | Steam | Flatpak `com.valvesoftware.Steam` nur wenn Karsten fragt |

## Was von der Windows-Partition zu holen ist

Die Windows-Partition (NTFS, 557 GB) ist unter Linux lesbar, BitLocker wurde am 2026-09-02 entschlüsselt. Einhängen: `sudo mkdir -p /mnt/win && sudo mount -t ntfs3 -o ro /dev/nvme0n1p3 /mnt/win`. Der Windows-Nutzer liegt unter `/mnt/win/Users/karst/`.

Kopieren, in dieser Reihenfolge:

1. `.ssh/` komplett nach `~/.ssh/` (Schlüssel `vitascore_ed25519`, `vitascore-prod`, `config`, `known_hosts`). Danach `chmod 700 ~/.ssh && chmod 600 ~/.ssh/*`. In `~/.ssh/config` den `IdentityAgent` auf `~/.1password/agent.sock` umstellen. Die Datei `hetzner-cloud-token.txt` gehört in 1Password, nicht auf die Platte.
2. `Documents/Obsidian/` nach `~/Documents/Obsidian/`.
3. `Documents/Repositories/` nach `~/Repositories/`, ohne `node_modules` (sind schon gelöscht). Danach in jedem Repo `pnpm install` erst bei Bedarf.
4. `.claude/` nach `~/.claude/` (Hooks, Skripte, Memory). Windows-Pfade in `settings.json` anpassen: der Hook `block-pr-merge.cjs` und das SessionEnd-Sync-Skript zeigen auf `C:/Users/karst/...`.
5. `.lmstudio/models/` nach `~/.lmstudio/models/` und `AppData/Roaming/memozero/models/` an den Ort, den memozero unter Linux erwartet. Zusammen 126 GB, dauert.
6. `.t3/` nur, wenn T3 Code für Linux existiert.

## Git und Konten

- `git config --global user.name "KarstenKreh"`, `user.email "60428712+KarstenKreh@users.noreply.github.com"`
- GitHub-Login `KarstenKreh`, `gh auth login` im Browser.
- Standard-Branch `main`.

## Nicht machen

- Keine 40 Dev-Pakete per apt. System über apt, Apps über Flatpak, Dev über Docker.
- Keine Alternativen für Wispr Flow oder Affinity installieren, ohne zu fragen.
- Nichts doppelt halten: Proton Drive und SharePoint nur per rclone bei Bedarf, keine lokalen Vollkopien.
- Kommentare in Code sind verboten, siehe AGENTS.md.
