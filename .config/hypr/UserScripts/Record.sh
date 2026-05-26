#!/bin/bash

SAVE_DIR="$HOME/Videos/Recordings"
mkdir -p "$SAVE_DIR"

FILENAME="$SAVE_DIR/$(date '+%Y-%m-%d_%H-%M-%S').mp4"

wf-recorder -f "$FILENAME"
