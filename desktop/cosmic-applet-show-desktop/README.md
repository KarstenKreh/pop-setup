# cosmic-applet-show-desktop

Panel-Knopf fuer COSMIC wie "Desktop anzeigen" in Windows. Ein Klick startet
`~/.local/bin/show-desktop` (Quelle in `~/.local/src/show-desktop`): sind Fenster offen,
werden alle minimiert; sind alle weg, kommen die zuvor minimierten zurueck.
Dasselbe liegt auf `Super+D`.

## Bauen

    PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig-shim CARGO_TARGET_DIR=$HOME/.local/src/cosmic-applet-nightlight/target cargo build --release

Der Target-Ordner wird mit dem Nachtlicht-Applet geteilt, damit libcosmic nicht zweimal gebaut wird.

## Installieren

    cp $HOME/.local/src/cosmic-applet-nightlight/target/release/cosmic-applet-show-desktop ~/.local/bin/
    cp org.chaoskarsten.CosmicAppletShowDesktop.desktop ~/.local/share/applications/

Dann `org.chaoskarsten.CosmicAppletShowDesktop` in
`~/.config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings` eintragen.
