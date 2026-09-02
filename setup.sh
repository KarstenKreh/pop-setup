#!/usr/bin/env bash
set -euo pipefail

FLATPAK_APPS=(
  com.brave.Browser
  md.obsidian.Obsidian
  me.proton.Mail
  org.signal.Signal
  com.slack.Slack
  org.telegram.desktop
  com.discordapp.Discord
  us.zoom.Zoom
  org.blender.Blender
  org.audacityteam.Audacity
  org.videolan.VLC
  com.visualstudio.code
)
APT_BASE=(git curl wget ca-certificates gnupg unzip htop timeshift rclone ntfs-3g)
TAILSCALE_AUTHKEY="${TAILSCALE_AUTHKEY:-}"

STATE_DIR="$HOME/.pop-setup/done"
LOG="$HOME/pop-setup.log"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRESS="$REPO_DIR/FORTSCHRITT.md"
mkdir -p "$STATE_DIR"
exec > >(tee -a "$LOG") 2>&1

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
done_marker() { touch "$STATE_DIR/$1"; }
is_done() { [[ -f "$STATE_DIR/$1" ]]; }
mark_progress() {
  local key="$1"
  [[ -f "$PROGRESS" ]] || return 0
  sed -i "s/^- \[ \] $key/- [x] $key/" "$PROGRESS"
}

run_step() {
  local name="$1"; shift
  if is_done "$name"; then
    say "$name: schon erledigt, übersprungen"
    return 0
  fi
  say "$name"
  "$@"
  done_marker "$name"
  mark_progress "$name"
}

step_nvidia_check() {
  if ! command -v nvidia-smi >/dev/null; then
    echo "nvidia-smi fehlt. Falsche ISO oder Treiber nicht geladen. Abbruch."
    exit 1
  fi
  nvidia-smi
}

step_apt_base() {
  sudo apt-get update
  sudo apt-get install -y "${APT_BASE[@]}"
}

step_timeshift_config() {
  local root_uuid
  root_uuid="$(findmnt -no UUID /)"
  sudo mkdir -p /etc/timeshift
  sudo tee /etc/timeshift/timeshift.json >/dev/null <<EOF
{
  "backup_device_uuid" : "$root_uuid",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "false",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "false",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [ "/home/**" ],
  "exclude-apps" : []
}
EOF
}

snapshot() {
  sudo timeshift --create --comments "$1" --tags O || echo "Snapshot fehlgeschlagen, weiter."
}

step_snapshot_before() { snapshot "vor Setup-Skript"; }

step_system_upgrade() {
  sudo apt-get update
  sudo apt-get full-upgrade -y
  sudo apt-get autoremove -y
}

step_firmware() {
  sudo fwupdmgr refresh --force || true
  sudo fwupdmgr get-updates || true
}

step_flatpak() {
  sudo apt-get install -y flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  for app in "${FLATPAK_APPS[@]}"; do
    flatpak install -y --noninteractive flathub "$app" || echo "Flatpak $app nicht installiert, weiter."
  done
}

step_onepassword() {
  curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main" | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
  sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ /usr/share/debsig/keyrings/AC2D62742012EA22
  curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
  curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
  sudo apt-get update
  sudo apt-get install -y 1password 1password-cli
}

step_github_cli() {
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y gh
}

step_node_fnm() {
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env)"
  fnm install --lts
  fnm default lts-latest
  grep -q 'fnm env' "$HOME/.bashrc" || cat >>"$HOME/.bashrc" <<'EOF'
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd --shell bash)"
EOF
}

step_claude_code() {
  curl -fsSL https://claude.ai/install.sh | bash
  grep -q '.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.bashrc"
}

step_docker() {
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  local codename
  codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-noble}")"
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  sudo systemctl enable --now docker
}

step_nvidia_container_toolkit() {
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -sS -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  sudo docker run --rm --gpus all ubuntu nvidia-smi
}

step_tailscale() {
  curl -fsSL https://tailscale.com/install.sh | sh
  if [[ -n "$TAILSCALE_AUTHKEY" ]]; then
    sudo tailscale up --auth-key="$TAILSCALE_AUTHKEY"
  else
    echo "Tailscale ist installiert. Anmelden mit:  sudo tailscale up"
  fi
}

step_cosmic_dark() {
  local dir="$HOME/.config/cosmic/com.system76.CosmicTheme.Mode/v1"
  mkdir -p "$dir"
  echo "true" >"$dir/is_dark"
}

step_snapshot_after() { snapshot "nach Setup-Skript"; }

run_step nvidia_check step_nvidia_check
run_step apt_base step_apt_base
run_step timeshift_config step_timeshift_config
run_step snapshot_before step_snapshot_before
run_step system_upgrade step_system_upgrade
run_step firmware step_firmware
run_step flatpak step_flatpak
run_step onepassword step_onepassword
run_step github_cli step_github_cli
run_step node_fnm step_node_fnm
run_step claude_code step_claude_code
run_step docker step_docker
run_step nvidia_container_toolkit step_nvidia_container_toolkit
run_step tailscale step_tailscale
run_step cosmic_dark step_cosmic_dark
run_step snapshot_after step_snapshot_after

say "Fertig. Log: $LOG"
echo "Einmal ab- und wieder anmelden, damit Docker ohne sudo geht."
echo "Danach: gh auth login, claude, sudo tailscale up (falls noch nicht)."
