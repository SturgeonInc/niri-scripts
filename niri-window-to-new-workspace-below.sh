#!/usr/bin/env sh

# shellcheck disable=SC2046 # ignore splitting
set -- $(
  niri msg --json workspaces |
    jq '
    ( max_by(.idx) | .id ),
    ( .[] | select(.is_focused) | .idx)
  '
)

DEST_WS_ID=$1
CURRENT_WS_IDX=$2

niri msg action move-window-to-workspace "$DEST_WS_ID"
niri msg action move-workspace-to-index "$(echo "$CURRENT_WS_IDX + 1" | bc)"
