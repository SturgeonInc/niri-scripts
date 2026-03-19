#!/usr/bin/env sh
set -e

LOG_FILE=$(realpath ~/.screentime.csv)
readonly SAMPLE_INTERVAL=1m
readonly IDLE_SAMPLE_INTERVAL=5m

readonly MAX_FILE_LINES=100'000'
# in hours
readonly GARBAGE_COLLECTION_INTERVAL=24
readonly CSV_HEADER='"TIME","TITLE","APP_ID"'

if [ -z "$LOG_FILE" ] || [ -z "$MAX_FILE_LINES" ]; then
  >&2 echo "Missing log file"
  exit 1
fi

last_garbage_collection=$(date +%s)

if ! [ -f "$LOG_FILE" ]; then
  echo "$CSV_HEADER" >"$LOG_FILE"
fi

while true; do
  state=$(loginctl show-user "$USER" --property State)
  idlehint=$(loginctl show-user "$USER" --property IdleHint)
  current_time=$(date +%s)
  hrs_since_gc=$(echo "($current_time - $last_garbage_collection) / 60" | bc)

  if [ -n "$MAX_FILE_LINES" ] &&
    [ "$hrs_since_gc" -gt "$GARBAGE_COLLECTION_INTERVAL" ] &&
    [ "$(cat "$LOG_FILE" | wc --lines)" -gt "$MAX_FILE_LINES" ]; then
    cp "$LOG_FILE" "$LOG_FILE~" &&
      echo "$CSV_HEADER" >"$LOG_FILE" &&
      (cat "$LOG_FILE~" | tail --lines "$MAX_FILE_LINES" >>"$LOG_FILE") &&
      rm "$LOG_FILE~"

    last_garbage_collection=$(date +%s)
  fi

  if ! [ "$state" = "State=active" ] || [ "$idlehint" = "IdleHint=yes" ]; then
    sleep "$IDLE_SAMPLE_INTERVAL"
    continue
  fi

  res=$(
    niri msg --json windows |
      jq '.[] | select(.is_focused) | [.app_id, .title]' |
      jq --raw-output @csv
  )

  timestamp=$(date --iso-8601=minutes)

  echo "\"$timestamp\",$res" >>"$LOG_FILE"
  sleep "$SAMPLE_INTERVAL"
done
