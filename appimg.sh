#!/usr/bin/env sh
set -e

NOTIFICATION_TITLE="$(basename "$0"): Error"
: "${APPIMAGE_HOME:=$HOME/.local/share/AppImage}"

if [ $# -lt 1 ]; then
  notify-send "$NOTIFICATION_TITLE" "Expected at least one argument"
  >&2 echo "$NOTIFICATION_TITLE" "Expected at least one argument"
  exit 1
fi

appglob=$1
shift

if ! [ -d "$APPIMAGE_HOME" ]; then
  notify-send "$NOTIFICATION_TITLE" "Could not find AppImage directory at '$APPIMAGE_HOME'"
  >&2 echo "Could not find AppImage corresponding to '$appglob'"
  exit 1
fi

app=$(find "$APPIMAGE_HOME" -name "$appglob.AppImage" -type f)
if [ -z "$app" ]; then
  notify-send "$NOTIFICATION_TITLE" "Could not find AppImage corresponding to '$appglob'"
  >&2 echo "Could not find AppImage corresponding to '$appglob'"
  exit 1
fi

if [ "$(echo "$app" | wc --lines)" -ne 1 ]; then
  notify-send "$NOTIFICATION_TITLE" "'$appglob' is ambiguous"
  >&2 echo "AppImage '$appglob' is ambiguous"
  exit 1
fi

if ! [ -x "$app" ]; then
  notify-send "$NOTIFICATION_TITLE" "'$app' lacks execute permissions"
  >&2 echo "AppImage '$app' lacks execute permissions"
  exit 1
fi

exec "$app" "$@"
