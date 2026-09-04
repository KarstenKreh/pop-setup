#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for x in info management; do
  wayland-scanner client-header cosmic-toplevel-$x-unstable-v1.xml cosmic-toplevel-$x-unstable-v1-client-protocol.h
  wayland-scanner private-code cosmic-toplevel-$x-unstable-v1.xml cosmic-toplevel-$x-unstable-v1-protocol.c
done
gcc -O2 -o show-desktop show-desktop.c stubs.c cosmic-toplevel-info-unstable-v1-protocol.c cosmic-toplevel-management-unstable-v1-protocol.c $(pkg-config --cflags --libs wayland-client)
install -m 755 show-desktop "$HOME/.local/bin/show-desktop"
