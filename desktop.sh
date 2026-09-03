#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D="$REPO_DIR/desktop"
STATE_DIR="$HOME/.pop-setup/done-desktop"
LOG="$HOME/pop-desktop.log"
PROGRESS="$REPO_DIR/FORTSCHRITT.md"
mkdir -p "$STATE_DIR" "$HOME/.local/bin" "$HOME/.local/src"
exec > >(tee -a "$LOG") 2>&1

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
is_done() { [[ -f "$STATE_DIR/$1" ]]; }
mark_progress() { [[ -f "$PROGRESS" ]] && sed -i "s/^- \[ \] $1/- [x] $1/" "$PROGRESS" || true; }
run_step() {
  local name="$1"; shift
  if is_done "$name"; then say "$name: schon erledigt, übersprungen"; return 0; fi
  say "$name"; "$@"; touch "$STATE_DIR/$name"; mark_progress "$name"
}
install_home() { sed "s|%HOME%|$HOME|g" "$1" > "$2"; }

step_apt_desktop() {
  sudo apt-get update
  sudo apt-get install -y build-essential libwayland-dev wl-clipboard python3-gi gir1.2-gtk-3.0
}

step_nightlight() {
  local src="$HOME/.local/src/cosmic-nightlight"
  mkdir -p "$src" "$HOME/.config/cosmic-nightlight" "$HOME/.config/systemd/user"
  cp "$D"/nightlight/*.c "$D"/nightlight/*.h "$D"/nightlight/*.xml "$D"/nightlight/README.md "$src/"
  gcc -O2 -o "$src/cosmic-nightlight" "$src/nightlight.c" "$src/wlr-layer-shell-protocol.c" -lwayland-client -lm
  install -m 755 "$src/cosmic-nightlight" "$HOME/.local/bin/cosmic-nightlight"
  install -m 755 "$D/nightlight/nightlight" "$HOME/.local/bin/nightlight"
  install -m 755 "$D/nightlight/nightlight-toggle" "$HOME/.local/bin/nightlight-toggle"
  [[ -f "$HOME/.config/cosmic-nightlight/config" ]] || cp "$D/nightlight/config.example" "$HOME/.config/cosmic-nightlight/config"
  install_home "$D/systemd/cosmic-nightlight.service" "$HOME/.config/systemd/user/cosmic-nightlight.service"
  systemctl --user daemon-reload
  systemctl --user enable --now cosmic-nightlight.service || echo "Nightlight startet erst in der grafischen Sitzung."
}

step_keytap() {
  mkdir -p "$HOME/.local/src/keytap"
  cp "$D/keytap/keytap.c" "$HOME/.local/src/keytap/"
  gcc -O2 -Wall -o "$HOME/.local/bin/keytap" "$HOME/.local/src/keytap/keytap.c"
}

step_op_fill() {
  install -m 755 "$D/op-fill/op-fill" "$HOME/.local/bin/op-fill"
  install -m 755 "$D/op-fill/op-pick" "$HOME/.local/bin/op-pick"
}

step_audio() {
  mkdir -p "$HOME/.config/pipewire/pipewire.conf.d" "$HOME/.config/wireplumber/wireplumber.conf.d"
  cp "$D/audio/hearing-filter.conf" "$HOME/.config/pipewire/pipewire.conf.d/"
  cp "$D/audio/50-kein-headset-autoswitch.conf" "$HOME/.config/wireplumber/wireplumber.conf.d/"
  systemctl --user restart pipewire wireplumber pipewire-pulse || true
  local mic
  mic="$(pactl list short sources 2>/dev/null | awk '/alsa_input/ && !/monitor/ {print $2; exit}')"
  [[ -n "$mic" ]] && pactl set-default-source "$mic" || true
}

step_cosmic() {
  local c="$HOME/.config/cosmic"
  mkdir -p "$c/com.system76.CosmicComp/v1" "$c/com.system76.CosmicSettings.Shortcuts/v1" \
           "$c/com.system76.CosmicPanel.Dock/v1" "$c/com.system76.CosmicPanel.Panel/v1" "$c/com.system76.CosmicTheme.Mode/v1"
  cp "$D"/cosmic/comp/* "$c/com.system76.CosmicComp/v1/"
  install_home "$D/cosmic/shortcuts/custom" "$c/com.system76.CosmicSettings.Shortcuts/v1/custom"
  cp "$D"/cosmic/dock/* "$c/com.system76.CosmicPanel.Dock/v1/"
  cp "$D"/cosmic/panel/* "$c/com.system76.CosmicPanel.Panel/v1/" 2>/dev/null || true
  cp "$D/cosmic/theme/is_dark" "$c/com.system76.CosmicTheme.Mode/v1/is_dark"
}

step_wispr_flow() {
  local url deb
  url="$(curl -fsSL https://api.github.com/repos/wispr-flow-linux/wispr-flow-linux/releases/latest \
        | grep -o 'https://[^"]*_amd64\.deb' | head -1)"
  [[ -n "$url" ]] || { echo "Kein Wispr-Flow-Paket gefunden, weiter."; return 0; }
  deb="/tmp/$(basename "$url")"
  curl -fL -o "$deb" "$url"
  sudo apt-get install -y "$deb"
  sudo usermod -aG input "$USER"
  mkdir -p "$HOME/.local/share/applications" "$HOME/.config/autostart"
  cp "$D/wispr-flow/wispr-flow.desktop" "$HOME/.local/share/applications/wispr-flow.desktop"
  cp "$D/wispr-flow/wispr-flow.desktop" "$HOME/.config/autostart/wispr-flow.desktop"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
}

step_wispr_prefs() {
  local cfg="$HOME/.config/Wispr Flow/config.json"
  if [[ ! -f "$cfg" ]]; then
    echo "Wispr Flow noch nie gestartet. Erst anmelden, dann desktop.sh erneut laufen lassen."
    return 1
  fi
  python3 - "$cfg" "$D/wispr-flow/prefs-patch.json" <<'PY'
import json, sys
cfg, patch = sys.argv[1], sys.argv[2]
d = json.load(open(cfg))
d.setdefault("prefs", {}).setdefault("user", {}).update(json.load(open(patch)))
json.dump(d, open(cfg, "w"))
print("Wispr-Flow-Einstellungen gesetzt:", json.load(open(patch)))
PY
}

step_onepassword_desktop() {
  mkdir -p "$HOME/.config/autostart" "$HOME/.ssh"
  cp "$D/autostart/1password.desktop" "$HOME/.config/autostart/"
  if [[ ! -f "$HOME/.ssh/config" ]] || ! grep -q "1password/agent.sock" "$HOME/.ssh/config"; then
    cat "$D/ssh/config" >> "$HOME/.ssh/config"
  fi
  chmod 600 "$HOME/.ssh/config"
}

step_environment() {
  mkdir -p "$HOME/.config/environment.d"
  cp "$D"/environment.d/*.conf "$HOME/.config/environment.d/"
}

step_monkey_mode() {
  mkdir -p "$HOME/.config/systemd/user"
  cp "$D/systemd/monkey-mode.service" "$D/systemd/monkey-mode.timer" "$HOME/.config/systemd/user/"
  systemctl --user daemon-reload
  if [[ -f "$HOME/Documents/Obsidian/.claude/scripts/tagesliste.py" ]]; then
    systemctl --user enable --now monkey-mode.timer
  else
    echo "Obsidian-Vault mit tagesliste.py fehlt noch, Timer wird spaeter aktiviert."
  fi
}

run_step apt_desktop step_apt_desktop
run_step environment step_environment
run_step nightlight step_nightlight
run_step keytap step_keytap
run_step op_fill step_op_fill
run_step audio step_audio
run_step cosmic step_cosmic
run_step onepassword_desktop step_onepassword_desktop
run_step wispr_flow step_wispr_flow
run_step wispr_prefs step_wispr_prefs || true
run_step monkey_mode step_monkey_mode

say "Fertig. Log: $LOG"
echo "Einmal ab- und wieder anmelden (input-Gruppe, COSMIC-Einstellungen, Autostart)."
echo "Danach von Hand: Wispr Flow anmelden, 1Password: Systemauthentifizierung + CLI-Integration einschalten."
