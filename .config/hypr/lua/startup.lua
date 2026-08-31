local commands = {
    "/home/louistran/.config/hypr/initial-boot.sh",
    "nm-applet",
    "blueman-applet",
    "hypridle",
    "hyprpaper",
    "gnome-keyring-daemon --start --components=secrets",
    "swww-daemon --format xrgb",
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "/home/louistran/.config/hypr/scripts/Dropterminal.sh ghostty &",
    "/home/louistran/.config/hypr/scripts/Polkit.sh",
    "nm-applet --indicator",
    "fcitx5 -d",
    "nm-tray",
    "sleep 2 && /home/louistran/.local/bin/waybar",
    "qs -c overview",
    "/home/louistran/.config/hypr/scripts/Hyprsunset.sh init",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
    "/home/louistran/.config/hypr/scripts/KeybindsLayoutInit.sh",
    "sleep 1 && nohup bash /home/louistran/.config/swaync/scripts/swaync-daemon.sh > /dev/null 2>&1 &",
}

hl.on("hyprland.start", function()
    for _, command in ipairs(commands) do
        hl.exec_cmd(command)
    end
end)
