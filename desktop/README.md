# desktop: Feineinstellungen für COSMIC

Alles, was nach `setup.sh` von Hand oder per Agent dazukam. `../desktop.sh` spielt es ein, mehrfach startbar.

| Ordner | Was | Zielort |
|---|---|---|
| `nightlight/` | Eigenbau-Nachtlicht (COSMIC hat keins, Overlay per Layer-Shell). Zeitplan in `config.example` | `~/.local/src/cosmic-nightlight`, `~/.local/bin/nightlight`, `~/.config/cosmic-nightlight/config` |
| `keytap/` | Tastendrücke per `/dev/uinput`, Basis für `op-fill` | `~/.local/bin/keytap` |
| `op-fill/` | 1Password-Zugangsdaten in beliebige Fenster tippen (`Super+Shift+P`) | `~/.local/bin/op-fill`, `op-pick` |
| `audio/` | Höhenschutz (High-Shelf -4 dB ab 8 kHz) als PipeWire-Smart-Filter; kein Umschalten auf das Headset-Mikro | `~/.config/pipewire/…`, `~/.config/wireplumber/…` |
| `cosmic/` | Maus (Scrollen mit gedrückter mittlerer Taste), Touchpad (Natural Scroll), Tastatur (de + neo_qwertz), Tiling, Tastenkürzel, Dock, dunkles Theme | `~/.config/cosmic/…` |
| `wispr-flow/` | Inoffizieller Linux-Port, Start im XWayland-Modus, Leiste rechts und im Ruhezustand versteckt | `.deb`, `~/.local/share/applications`, `~/.config/autostart`, `~/.config/Wispr Flow/config.json` |
| `autostart/`, `ssh/` | 1Password beim Anmelden, SSH-Agent von 1Password | `~/.config/autostart`, `~/.ssh/config` |
| `environment.d/` | PATH und Standardbrowser für die grafische Sitzung | `~/.config/environment.d` |
| `systemd/` | User-Service für das Nachtlicht (`%HOME%` wird ersetzt); Timer für Monkey Mode (10, 16, 22 Uhr, nur am Netzteil, holt Verpasstes nach) | `~/.config/systemd/user` |

Tastenkürzel: `Super+Shift+N` Nachtlicht an/aus, `Super+Shift+P` 1Password ausfüllen, `Super+Shift+S` Screenshot.

Was das Skript nicht kann und von Hand bleibt: Wispr Flow anmelden, 1Password anmelden und dort
"Mit Systemauthentifizierung entsperren" sowie "Mit 1Password CLI integrieren" einschalten,
Bluetooth-Kopfhörer koppeln.
