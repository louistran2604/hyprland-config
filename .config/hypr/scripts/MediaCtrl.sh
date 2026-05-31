#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl

music_icon="$HOME/.config/swaync/icons/music.png"

# Wait for player to reach "Playing" state after a track change.
# Retries every 100ms for up to 1.5 seconds.
# This fixes the race condition where playerctl status still returns
# "Paused" during the gap between tracks (common with Spotify/YouTube).
wait_for_playing() {
  for i in $(seq 1 15); do
    status=$(playerctl status 2>/dev/null)
    if [[ "$status" == "Playing" ]]; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

# Play the next track
play_next() {
  playerctl next
  if wait_for_playing; then
    song_title=$(playerctl metadata title 2>/dev/null)
    song_artist=$(playerctl metadata artist 2>/dev/null)
    notify-send -e -u low -i $music_icon "Now Playing:" "$song_title by $song_artist"
  else
    # Timed out waiting for Playing - show whatever status we have
    show_music_notification
  fi
}

# Play the previous track
play_previous() {
  playerctl previous
  if wait_for_playing; then
    song_title=$(playerctl metadata title 2>/dev/null)
    song_artist=$(playerctl metadata artist 2>/dev/null)
    notify-send -e -u low -i $music_icon "Now Playing:" "$song_title by $song_artist"
  else
    # Timed out waiting for Playing - show whatever status we have
    show_music_notification
  fi
}

# Toggle play/pause
toggle_play_pause() {
  playerctl play-pause
  sleep 0.1
  show_music_notification
}

# Stop playback
stop_playback() {
  playerctl stop
  notify-send -e -u low -i $music_icon " Playback:" " Stopped"
}

# Display notification with song information
show_music_notification() {
  status=$(playerctl status 2>/dev/null)
  if [[ "$status" == "Playing" ]]; then
    song_title=$(playerctl metadata title 2>/dev/null)
    song_artist=$(playerctl metadata artist 2>/dev/null)
    notify-send -e -u low -i $music_icon "Now Playing:" "$song_title by $song_artist"
  elif [[ "$status" == "Paused" ]]; then
    notify-send -e -u low -i $music_icon " Playback:" " Paused"
  fi
}

# Get media control action from command line argument
case "$1" in
"--nxt")
  play_next
  ;;
"--prv")
  play_previous
  ;;
"--pause")
  toggle_play_pause
  ;;
"--stop")
  stop_playback
  ;;
*)
  echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
  exit 1
  ;;
esac
