#!/bin/bash
set -e

echo "Installing base icon themes..."
sudo pacman -S --noconfirm --needed adwaita-icon-theme hicolor-icon-theme 2>/dev/null || true

echo "Updating icon caches..."
for dir in /usr/share/icons/*/; do
  gtk-update-icon-cache -f "$dir" 2>/dev/null || true
  gtk4-update-icon-cache -f "$dir" 2>/dev/null || true
done

echo "Symlinking host icon themes from /run/host..."
if [ -d /run/host/usr/share/icons ]; then
  for theme_dir in /run/host/usr/share/icons/*/; do
    theme_name=$(basename "$theme_dir")
    target="/usr/share/icons/$theme_name"
    if [ ! -d "$target" ] && [ ! -L "$target" ]; then
      sudo ln -sf "$theme_dir" "$target" 2>/dev/null || true
      echo "  Linked: $theme_name"
    fi
  done
fi

if [ -d /run/host/usr/share/pixmaps ] && [ ! -L /usr/share/pixmaps-host ]; then
  sudo ln -sf /run/host/usr/share/pixmaps /usr/share/pixmaps-host 2>/dev/null || true
fi

echo "Final icon cache update..."
for dir in /usr/share/icons/*/; do
  gtk4-update-icon-cache -f "$dir" 2>/dev/null || true
done

echo "Icon setup complete."
