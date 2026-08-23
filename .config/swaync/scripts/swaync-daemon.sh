#!/bin/bash
# ──────────────────────────────────────────────────────────
# swaync-daemon.sh — Start swaync and save its D-Bus address
# Usage: bash ~/.config/swaync/scripts/swaync-daemon.sh
# ──────────────────────────────────────────────────────────

# Save the host's D-Bus address to a file for later use
ADDR_FILE="$HOME/.config/swaync/.dbus_address"
echo "${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}" > "$ADDR_FILE"

# Cap notification body text at 5 lines (see ~/.local/lib/swaync-clamp5.c)
distrobox-enter -n swaync -- env \
  DBUS_SESSION_BUS_ADDRESS="$(cat "$ADDR_FILE")" \
  GDK_BACKEND=wayland \
  GSK_RENDERER=cairo \
  LIBGL_ALWAYS_SOFTWARE=1 \
  GTK_THEME=Adwaita:dark \
  LD_PRELOAD="$HOME/.local/lib/swaync-clamp5.so" \
  swaync
