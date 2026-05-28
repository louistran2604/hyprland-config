#!/bin/bash
# ML4W Volume - edited for swaync glass theme
# uses full-color icons (not symbolic)

get_volume() {
  pamixer --get-volume
}

get_icon() {
  vol=$(get_volume)
  mute=$(pamixer --get-mute)
  if [ "$mute" = "true" ]; then
    echo "audio-volume-muted"          # was audio-volume-muted-symbolic
  elif [ "$vol" -ge 70 ]; then
    echo "audio-volume-high"           # was audio-volume-high-symbolic
  elif [ "$vol" -ge 30 ]; then
    echo "audio-volume-medium"         # was audio-volume-medium-symbolic
  else
    echo "audio-volume-low"            # was audio-volume-low-symbolic
  fi
}

get_mic_icon() {
  mute=$(pamixer --default-source --get-mute)
  if [ "$mute" = "true" ]; then
    echo "microphone-sensitivity-muted"  # was ...-muted-symbolic
  else
    echo "microphone-sensitivity-high"   # was ...-high-symbolic
  fi
}

notify_vol() {
  vol=$(get_volume)
  icon=$(get_icon)
  notify-send -a "Volume" -u low \
    -h string:x-canonical-private-synchronous:volume \
    -h int:value:"$vol" \
    -i "$icon" "Volume Level:" "${vol}%"
}

notify_mic() {
  vol=$(pamixer --default-source --get-volume)
  icon=$(get_mic_icon)
  notify-send -a "Volume" -u low \
    -h string:x-canonical-private-synchronous:mic \
    -h int:value:"$vol" \
    -i "$icon" "Mic Level:" "${vol}%"
}

inc_volume() { pamixer -i "$1"; notify_vol; }
dec_volume() { pamixer -d "$1"; notify_vol; }

inc_volume_precise() { pamixer -i 1; notify_vol; }
dec_volume_precise() { pamixer -d 1; notify_vol; }

toggle_mute() {
  pamixer -t
  if [ "$(pamixer --get-mute)" = "true" ]; then
    notify-send -a "Volume" -u low -h string:x-canonical-private-synchronous:volume \
      -i "audio-volume-muted" "Volume:" "Muted"
  else
    notify_vol
  fi
}

toggle_mic() { pamixer --default-source -t; notify_mic; }
inc_mic_volume() { pamixer --default-source -i 5; notify_mic; }
dec_mic_volume() { pamixer --default-source -d 5; notify_mic; }

case "$1" in
"--get") get_volume ;;
"--inc") inc_volume 5 ;;
"--inc-precise") inc_volume_precise ;;
"--dec") dec_volume 5 ;;
"--dec-precise") dec_volume_precise ;;
"--toggle") toggle_mute ;;
"--toggle-mic") toggle_mic ;;
"--get-icon") get_icon ;;
"--get-mic-icon") get_mic_icon ;;
"--mic-inc") inc_mic_volume ;;
"--mic-dec") dec_mic_volume ;;
*) get_volume ;;
esac
