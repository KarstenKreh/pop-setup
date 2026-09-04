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
- `~/.local/bin/nightlight` — Steuerskript (`off`, `on`, `auto`, `temp`, `strength`, `dim`, `status`)
- `~/.config/cosmic-nightlight/config` — Einstellungen, wird alle 2 s neu eingelesen
- `~/.config/systemd/user/cosmic-nightlight.service` — Autostart

## Abdunkeln unter das Hardware-Minimum

`nightlight dim 0-90` mischt zusaetzlich Schwarz in dieselbe Overlay-Flaeche.
Gedacht fuer Laptops, deren Backlight schon am Minimum steht
(`/sys/class/backlight/intel_backlight/brightness`). Wirkt in derselben
Flaeche wie der Farbfilter, kein zweites Overlay. `mode=off` schaltet auch das
Abdunkeln ab.

Nebenwirkung: Schwarz bleibt schwarz, alles Helle wird dunkler, der Kontrast
sinkt also mit steigendem `dim`.

## Bekannte Grenze

Ein Overlay kann Farbe nur addieren, nicht multiplizieren. Schwarz wird dadurch
leicht angehoben. Bei "grauem Schwarz" `strength` senken, nicht `temp`.
