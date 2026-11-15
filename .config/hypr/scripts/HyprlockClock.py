#!/usr/bin/env python3
"""Render a cached, wallpaper-textured clock for Hyprlock's image widget."""

from datetime import datetime
import fcntl
import hashlib
from pathlib import Path
import re
import subprocess
import sys
import tempfile


def render_clock(config, cache, clock_text):
    text = config.read_text()
    background = re.search(r"background\s*\{([^}]+)\}", text)
    if not background:
        raise ValueError("Missing clock background")
    wallpaper = re.search(r"^\s*path = (.+)$", background[1], re.MULTILINE)
    colors = re.search(r"^# clock-colors = (#[\da-fA-F]{6}) (#[\da-fA-F]{6})$", text, re.MULTILINE)
    if not wallpaper or not colors:
        raise ValueError("Missing clock wallpaper or Wallust colors")
    wallpaper = Path(wallpaper[1].strip()).expanduser()
    tint, light = colors.groups()
    modified = wallpaper.stat().st_mtime_ns if wallpaper.is_file() else None
    key = hashlib.sha256(f"{clock_text}\n{text}\n{modified}".encode()).hexdigest()
    cache.mkdir(parents=True, exist_ok=True, mode=0o700)
    output, stamp = cache / "clock.png", cache / "clock.key"

    with (cache / "clock.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if output.is_file() and stamp.is_file() and stamp.read_text() == key:
            return output
        with tempfile.TemporaryDirectory(dir=cache) as temporary:
            temporary = Path(temporary)
            mask, texture, result = (temporary / name for name in ("mask.png", "texture.png", "clock.png"))
            subprocess.run([
                "pango-view", "--no-display", "--dpi=96", "--margin=0",
                "--font=Roboto Mono for Powerline Bold 96",
                "--background=transparent", "--foreground=white",
                "--markup", f'--text=<span letter_spacing="-5888">{clock_text}</span>', f"--output={mask}",
            ], check=True, capture_output=True)
            dimensions = subprocess.check_output(["identify", "-format", "%wx%h", str(mask)], text=True)
            try:
                # shortcut: sample the wallpaper center; use per-monitor crops for spatially exact glass.
                subprocess.run([
                    "convert", str(wallpaper), "-auto-orient", "-thumbnail", "640x360^",
                    "-gravity", "center", "-extent", "640x360", "-crop", dimensions + "+0+0",
                    "+repage", "-blur", "0x8", "-fill", tint, "-colorize", "18",
                    "-fill", light, "-colorize", "24", str(texture),
                ], check=True, capture_output=True)
            except subprocess.CalledProcessError:
                # Keep the current time readable if the selected wallpaper was removed or cannot be decoded.
                subprocess.run(["convert", "-size", dimensions, "xc:" + light, str(texture)], check=True, capture_output=True)
            subprocess.run([
                "convert", str(texture), str(mask), "-alpha", "on", "-compose", "CopyOpacity",
                "-composite", "-channel", "A", "-evaluate", "multiply", "0.92", "+channel", str(result),
            ], check=True, capture_output=True)
            result.replace(output)
            stamp.write_text(key)
    return output


if __name__ == "__main__":
    try:
        print(render_clock(
            Path.home() / ".config/hypr/hyprlock.conf",
            Path.home() / ".cache/hyprlock",
            datetime.now().strftime("%H:%M"),
        ))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Hyprlock clock: {error}", file=sys.stderr)
        sys.exit(1)
