#!/usr/bin/env bash
set -eu
mkdir -p ~/.config/systemd/user
unit() {
  local remote="$1" dir="$2" svc="rclone-$1.service"
  mkdir -p "$dir"
  cat > ~/.config/systemd/user/"$svc" <<UNIT
[Unit]
Description=rclone mount $remote
After=network-online.target
[Service]
Type=notify
ExecStart=/usr/bin/rclone mount $remote: "$dir" --vfs-cache-mode full --vfs-cache-max-size 20G --dir-cache-time 1h --poll-interval 1m
ExecStop=/bin/fusermount3 -uz "$dir"
Restart=on-failure
RestartSec=10
[Install]
WantedBy=default.target
UNIT
  systemctl --user daemon-reload
  systemctl --user enable --now "$svc"
}
rclone listremotes | grep -qx 'proton:'      && unit proton      "$HOME/Proton Drive"
rclone listremotes | grep -qx 'sp-dktech:'   && unit sp-dktech   "$HOME/SharePoint/DK Tech Solutions UG"
rclone listremotes | grep -qx 'sp-memozero:' && unit sp-memozero "$HOME/SharePoint/memozero"
rclone listremotes | grep -qx 'sp-safina:'   && unit sp-safina   "$HOME/SharePoint/Safina AI"
sleep 3; systemctl --user --no-pager list-units 'rclone-*' ; ls "$HOME/Proton Drive" 2>/dev/null | head
