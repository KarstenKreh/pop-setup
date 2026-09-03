# cosmic-nightlight

Blaulichtfilter fuer COSMIC (Pop!_OS 24.04). COSMIC exportiert kein
`zwlr_gamma_control_manager_v1`, deshalb funktionieren gammastep, wlsunset und
redshift dort nicht. Dieses Tool legt stattdessen ein klickdurchlaessiges
Bernstein-Overlay per `zwlr_layer_shell_v1` ueber alle Bildschirme.

## Bauen

    gcc -O2 -o cosmic-nightlight nightlight.c wlr-layer-shell-protocol.c -lwayland-client -lm

Braucht `libwayland-dev`. Die eine `-Wformat-truncation`-Warnung ist harmlos.

## Installieren

    cp cosmic-nightlight ~/.local/bin/
    systemctl --user restart cosmic-nightlight

## Dateien

- `~/.local/bin/cosmic-nightlight` — das laufende Programm
- `~/.local/bin/nightlight` — Steuerskript (`off`, `on`, `auto`, `temp`, `strength`, `status`)
- `~/.config/cosmic-nightlight/config` — Einstellungen, wird alle 2 s neu eingelesen
- `~/.config/systemd/user/cosmic-nightlight.service` — Autostart

## Bekannte Grenze

Ein Overlay kann Farbe nur addieren, nicht multiplizieren. Schwarz wird dadurch
leicht angehoben. Bei "grauem Schwarz" `strength` senken, nicht `temp`.
