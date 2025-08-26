#!/usr/bin/env sh

TERM_NAME='the-foot'
>&2 echo Term name: "'$TERM_NAME'"

TERM_ID="$(niri msg --json windows | jq ".[] | select(.app_id == \"$TERM_NAME\").id")"
if [ -z "$TERM_ID" ]; then
  >&2 echo "Could not find window with app ID $TERM_NAME"
  exit 1
fi
>&2 echo Term window ID: "'$TERM_ID'"

TERM_WS_NAME=''

# needed for querying whether term is on active window
ACTIVE_WORKSPACE_ID="$(niri msg --json workspaces | jq '.[] | select(.is_active) | .id')"
>&2 echo Your active workspace ID: "'$ACTIVE_WORKSPACE_ID'"

# needed for moving window to workspace
ACTIVE_WORKSPACE_IDX="$(niri msg --json workspaces | jq '.[] | select(.is_active) | .idx')"
>&2 echo Your active workspace ID: "'$ACTIVE_WORKSPACE_IDX'"

if niri msg --json windows | jq --exit-status "
  .[] | select(.app_id == \"$TERM_NAME\") | .workspace_id == $ACTIVE_WORKSPACE_ID
"; then
  >&2 echo the foot focused, sending home
  niri msg action move-window-to-workspace "$TERM_WS_NAME" --window-id "$TERM_ID" --focus false
  niri msg action fullscreen-window --id "$TERM_ID"
else
  >&2 echo the foot not on workspace, bringing here
  niri msg action move-window-to-floating --id "$TERM_ID"
  niri msg action center-window --id "$TERM_ID"

  niri msg action move-window-to-workspace "$ACTIVE_WORKSPACE_IDX" --window-id "$TERM_ID" --focus true
  niri msg action focus-floating
fi
