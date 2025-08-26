#!/usr/bin/env sh

INTERVAL='1m'
BATTERY='/org/freedesktop/UPower/devices/battery_BAT1'
POWER_SUPPLY_STATUS='/sys/class/power_supply/BAT1/status'

# Thresholds (highest to lowest)
set -- 15 10 5

MINIMUM_THRESH="$1"
STATE=q0

while true; do
  PERC="$(upower -i "$BATTERY" | grep percentage)"
  PERC=${PERC##* } # get last word (percentage of battery)
  PERC=${PERC%\%}  # remove percentage sign

  STATE_PREV="$STATE"
  >&2 echo "STATE_PREV=$STATE_PREV"

  # state handling
  if [ "$PERC" -gt "$1" ]; then
    STATE="above${MINIMUM_THRESH}"
  else # STATE's final value is the last (and therefore loweset) threshold passed
    for thresh in "$@"; do
      if [ "$PERC" -le "$thresh" ]; then
        STATE="sub${thresh}"
      fi
    done
  fi
  >&2 echo "state is now $STATE"

  if [ "$(cat "$POWER_SUPPLY_STATUS")" != Charging ]; then
    >&2 echo 'Not charging'
    if [ "$STATE_PREV" != "$STATE" ] && [ "$PERC" -le "$MINIMUM_THRESH" ]; then
      >&2 echo "States different and perc <= $THRESH3; playing notification"
      notify-send --urgency=critical --icon "battery-empty" "LOW BATTERY WARNING: $PERC%"
      play /home/fisherman/Music/sound-effects/sound_ambient_alarms_portal_elevator_chime.wav
    fi # current vs prev state
  fi   # chargin

  sleep "$INTERVAL"
done
