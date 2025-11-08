#!/usr/bin/env sh

readonly INTERVAL='1m'
readonly BATTERY='/org/freedesktop/UPower/devices/battery_BAT1'
readonly POWER_SUPPLY_STATUS='/sys/class/power_supply/BAT1/status'

readonly CRIT_ALERT_SOUND="$HOME/Music/sound-effects/sound_ambient_alarms_portal_elevator_chime.wav"

# Thresholds (highest to lowest)
set -- 15 10 5

MINIMUM_THRESH="$1"
state=q0

while true; do
  perc="$(upower -i "$BATTERY" | grep percentage)"
  perc=${perc##* } # get last word (percentage of battery)
  perc=${perc%\%}  # remove percentage sign

  STATE_PREV="$state"
  >&2 echo "STATE_PREV=$STATE_PREV"

  # state handling
  if [ "$perc" -gt "$1" ]; then
    state="above${MINIMUM_THRESH}"
  else # STATE's final value is the last (and therefore loweset) threshold passed
    for thresh in "$@"; do
      if [ "$perc" -le "$thresh" ]; then
        state="sub${thresh}"
      fi
    done
  fi
  >&2 echo "state is now $state"

  if [ "$(cat "$POWER_SUPPLY_STATUS")" != Charging ]; then
    >&2 echo 'Not charging'
    if [ "$STATE_PREV" != "$state" ] && [ "$perc" -le "$MINIMUM_THRESH" ]; then
      >&2 echo "States different and perc <= $THRESH3; playing notification"
      notify-send --urgency=critical --icon "battery-empty" "LOW BATTERY WARNING: $perc%"
      play "$CRIT_ALERT_SOUND"
    fi # current vs prev state
  fi   # chargin

  sleep "$INTERVAL"
done
