#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl

music_icon="multimedia-player"

# Find the MPRIS player that is currently Playing.
# This is needed because bare "playerctl" targets the first player it finds
# (which might be a paused YouTube tab in Chrome instead of Spotify).
get_active_player() {
  # First: check for a player that is currently "Playing"
  local playing_player
  playing_player=$(playerctl -l 2>/dev/null | while read -r p; do
    if [[ "$(playerctl -p "$p" status 2>/dev/null)" == "Playing" ]]; then
      echo "$p"
      break
    fi
  done)

  if [[ -n "$playing_player" ]]; then
    echo "$playing_player"
    return 0
  fi

  # Fallback: if nothing is playing, check for a "Paused" player
  # (so play/pause toggle still works)
  local paused_player
  paused_player=$(playerctl -l 2>/dev/null | while read -r p; do
    if [[ "$(playerctl -p "$p" status 2>/dev/null)" == "Paused" ]]; then
      echo "$p"
      break
    fi
  done)

  if [[ -n "$paused_player" ]]; then
    echo "$paused_player"
    return 0
  fi

  return 1
}

# Wait for a specific player to reach "Playing" state after track change.
# Polls every 100ms for up to 2 seconds.
wait_for_playing() {
  local player="$1"
  for i in $(seq 1 20); do
    if [[ "$(playerctl -p "$player" status 2>/dev/null)" == "Playing" ]]; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

# Play the next track
play_next() {
  local player
  player=$(get_active_player) || { notify-send -e -u low -i "$music_icon" "No player found"; return 1; }
  playerctl -p "$player" next
  if wait_for_playing "$player"; then
    local song_title song_artist
    song_title=$(playerctl -p "$player" metadata title 2>/dev/null)
    song_artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
    notify-send -e -u low -i "$music_icon" "Now Playing:" "$song_title by $song_artist"
  else
    show_music_notification "$player"
  fi
}

# Play the previous track
play_previous() {
  local player
  player=$(get_active_player) || { notify-send -e -u low -i "$music_icon" "No player found"; return 1; }
  playerctl -p "$player" previous
  if wait_for_playing "$player"; then
    local song_title song_artist
    song_title=$(playerctl -p "$player" metadata title 2>/dev/null)
    song_artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
    notify-send -e -u low -i "$music_icon" "Now Playing:" "$song_title by $song_artist"
  else
    show_music_notification "$player"
  fi
}

# Toggle play/pause
toggle_play_pause() {
  local player
  player=$(get_active_player) || { notify-send -e -u low -i "$music_icon" "No player found"; return 1; }
  playerctl -p "$player" play-pause
  sleep 0.1
  show_music_notification "$player"
}

# Stop playback
stop_playback() {
  local player
  player=$(get_active_player) || { notify-send -e -u low -i "$music_icon" "No player found"; return 1; }
  playerctl -p "$player" stop
  notify-send -e -u low -i "$music_icon" " Playback:" " Stopped"
}

# Display notification with song information
show_music_notification() {
  local player="${1:-}"
  if [[ -z "$player" ]]; then
    player=$(get_active_player) || return 1
  fi

  local status
  status=$(playerctl -p "$player" status 2>/dev/null)
  if [[ "$status" == "Playing" ]]; then
    local song_title song_artist
    song_title=$(playerctl -p "$player" metadata title 2>/dev/null)
    song_artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
    notify-send -e -u low -i "$music_icon" "Now Playing:" "$song_title by $song_artist"
  elif [[ "$status" == "Paused" ]]; then
    notify-send -e -u low -i "$music_icon" " Playback:" " Paused"
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
