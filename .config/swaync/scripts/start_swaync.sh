#!/bin/bash
# Start swaync inside the distrobox container with the HOST's D-Bus session bus.
# This is CRITICAL — without it, swaync can't receive notifications from host apps.
set -e

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export GDK_BACKEND=wayland
export GSK_RENDERER=cairo
export LIBGL_ALWAYS_SOFTWARE=1
export GTK_THEME=Adwaita:dark
# Cap notification body text at 5 lines (see ~/.local/lib/swaync-clamp5.c)
export LD_PRELOAD="$HOME/.local/lib/swaync-clamp5.so"

echo "Starting swaync with DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
exec swaync
