#!/bin/bash
# ──────────────────────────────────────────────────────────
# swaync-ctrl.sh — Control swaync with the correct D-Bus address
#
# This reads the saved D-Bus address from the file that
# swaync-daemon.sh wrote, so swaync-client can always
# find the running daemon.
#
# Usage:
#   swaync-ctrl.sh -t         Toggle notification center
#   swaync-ctrl.sh -t -sw     Toggle (skip wait)
#   swaync-ctrl.sh -rs        Reload CSS
#   swaync-ctrl.sh -C         Close all notifications
#   swaync-ctrl.sh -sw        Just check if daemon is reachable
# ──────────────────────────────────────────────────────────

ADDR_FILE="$HOME/.config/swaync/.dbus_address"

if [ ! -f "$ADDR_FILE" ]; then
  echo "ERROR: $ADDR_FILE not found. Start swaync with swaync-daemon.sh first."
  exit 1
fi

DBUS_ADDR=$(cat "$ADDR_FILE")

distrobox-enter -n swaync -- env \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
  swaync-client "$@"
