#!/bin/env sh

DEFAULT_INTERVAL=0.2
INTERVAL=$2

if [ $# -lt 1 ]; then
  exit 1
fi

while true; do
  if LASTMOD="$(stat --format %y "$1")" && ! [ "$OLDMOD" = "$LASTMOD" ]; then
    OLDMOD="$LASTMOD"
    cat "$1"
  fi
  if ! sleep "${INTERVAL:-$DEFAULT_INTERVAL}"; then exit 1; fi
done
