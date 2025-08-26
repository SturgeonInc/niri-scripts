#!/usr/bin/env sh

STATE_FILE="/tmp/$HYPRLAND_INSTANCE_SIGNATURE-colmode"

if [ -f "$STATE_FILE" ]; then
  rm "$STATE_FILE"
  hyprctl --batch 'dispatch scroller:setmode row; notify 2 1000 0 "Row Mode"'
else
  touch "$STATE_FILE"
  hyprctl --batch 'dispatch scroller:setmode col; notify 0 1000 0 "Column Mode"'
fi
