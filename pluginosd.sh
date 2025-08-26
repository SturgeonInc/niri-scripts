#!/usr/bin/env sh

SOUND_EFFECT_FOLDER="$HOME/Music/sound-effects"
SOUND_EFFECT_DISCHARGE="$SOUND_EFFECT_FOLDER/button_synth_negative_02.wav"
SOUND_EFFECT_CHARGE="$SOUND_EFFECT_FOLDER/sound_buttons_button_synth_positive_01.wav"

VOLUME=0.5

upower --monitor-detail | while read -r LINE; do
  case "$LINE" in
  state:*discharging)
    if [ "$STATE" != DISCHARGING ]; then
      swayosd-client --custom-message="Battery Discharging" --custom-icon='battery-good-symbolic'
      play --volume "$VOLUME" "$SOUND_EFFECT_DISCHARGE"
      STATE=DISCHARGING
    fi
    ;;
  state:*pending-charge | state:*charging)
    if [ "$STATE" != CHARGING ]; then
      swayosd-client --custom-message="Battery Charging" --custom-icon='battery-full-charged-symbolic'
      play --volume "$VOLUME" "$SOUND_EFFECT_CHARGE"
      STATE=CHARGING
    fi
    ;;
  *) # do nothing
    ;;
  esac
done
