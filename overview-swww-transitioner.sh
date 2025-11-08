#!/usr/bin/env sh

readonly WALLPAPER="$HOME/Pictures/monstera-enhanced.png"
readonly WALLPAPER_OVERVIEW="$HOME/Pictures/monstera-enhanced-overview.png"

export SWWW_TRANSITION=fade
export SWWW_TRANSITION_DURATION=0.2

listener() {
  jq --unbuffered 'select(has("OverviewOpenedOrClosed")) | .[] | .is_open' |
    while read -r is_in_overview; do
      case "$is_in_overview" in
      true) swww img "$WALLPAPER_OVERVIEW" ;;
      false) swww img "$WALLPAPER" ;;
      *) >&2 echo "jq output unexpected result: '$is_in_overview'" ;;
      esac
    done
}

niri msg --json event-stream | listener
