#!/bin/bash
# ──────────────────────────────────────────────────────────
# restart_swaync.sh — Kill and restart swaync cleanly
# Usage: bash ~/.config/swaync/scripts/restart_swaync.sh
# ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Killing old swaync..."
distrobox-enter -n swaync -- killall swaync 2>/dev/null || true
killall swaync 2>/dev/null || true
sleep 1

# Remove stale D-Bus address file
rm -f "$HOME/.config/swaync/.dbus_address"

echo "Starting swaync..."
nohup bash "$SCRIPT_DIR/swaync-daemon.sh" > /dev/null 2>&1 &
disown

echo "Waiting for swaync to start..."
sleep 3

# Test if it's reachable
if bash "$SCRIPT_DIR/swaync-ctrl.sh" -sw 2>/dev/null; then
  echo "✓ swaync is running!"
else
  echo "⚠ swaync-client couldn't connect. Testing notification anyway..."
  notify-send -a "Volume" "Volume Level:" "50%"
fi
