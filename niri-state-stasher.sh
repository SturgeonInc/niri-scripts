#!/usr/bin/env sh

# Save niri workspace and window state to a file on some interval

NIRI_STATE_FILE="$HOME/.niri-state"
STASH_INTERVAL=2m
STASH_STATE_ONCE=0

usage() {
  >&2 echo "TODO"
}

for arg in "$@"; do
  case "$arg" in
  -f | --output-file)
    shift
    NIRI_STATE_FILE=$1
    ;;
  -i | --interval)
    shift
    STASH_INTERVAL=$1
    ;;
  -h | --help)
    usage
    exit
    ;;
  -1 | --once)
    STASH_INTERVAL=
    STASH_STATE_ONCE=1
    ;;
  *)
    >&2 echo "Argument '$1' not recognized."
    usage
    exit 1
    ;;
  esac

  shift
done

>&2 echo "Attempting to store state in '$NIRI_STATE_FILE' every ${STASH_INTERVAL:-[just once]}"
while true; do
  if ! [ -w "$NIRI_STATE_FILE" ]; then
    >&2 echo "Could not write to file '$NIRI_STATE_FILE'. Exiting."
    exit 1
  fi

  (
    niri msg --json workspaces
    niri msg --json windows
  ) | jq --slurp '{ "workspaces": .[0], "windows": .[1] }' >"$NIRI_STATE_FILE"

  if [ "$STASH_STATE_ONCE" -eq 1 ]; then
    exit
  fi

  sleep "$STASH_INTERVAL"
done
