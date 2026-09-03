#!/usr/bin/env bash
set -u
echo "== 1/2 Proton Drive =="
if rclone listremotes | grep -qx 'proton:'; then
  echo "proton: ist schon eingerichtet, uebersprungen."
else
  read -rp "Proton E-Mail: " u
  read -rsp "Proton Passwort: " p; echo
  read -rp "2FA-Code aus der Authenticator-App (leer lassen, wenn kein 2FA): " c
  if [[ -n "$c" ]]; then
    rclone config create proton protondrive username="$u" password="$p" 2fa="$c" --obscure --non-interactive >/dev/null
  else
    rclone config create proton protondrive username="$u" password="$p" --obscure --non-interactive >/dev/null
  fi
  rclone lsd proton: >/dev/null 2>&1 && echo "Proton Drive: Login OK" || { echo "Proton Drive: Login fehlgeschlagen. Skript nochmal starten."; rclone config delete proton; }
fi
echo
echo "== 2/2 SharePoint (Microsoft-Login im Browser) =="
for s in "sp-dktech|DK Tech Solutions UG" "sp-memozero|memozero" "sp-safina|Safina AI"; do
  name="${s%%|*}"; site="${s#*|}"
  if rclone listremotes | grep -qx "$name:"; then echo "$name: schon da, uebersprungen."; continue; fi
  echo
  echo "Jetzt kommt die Site '$site'. Gleich oeffnet sich der Browser. Danach im Terminal:"
  echo "  - Config type: 'sharepoint' waehlen"
  echo "  - Nach '$site' suchen und die Site auswaehlen, Drive 'Documents' bestaetigen"
  read -rp "Enter zum Starten..."
  rclone config create "$name" onedrive
done
echo
echo "Fertig. Vorhandene Remotes:"; rclone listremotes
