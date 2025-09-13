#!/usr/bin/env sh

CURRENT_WORKSPACE_NAME=$(
  niri msg --json workspaces |
    jq --raw-output '
      .[] | select(.is_focused) | .name |
      if . == null then
        empty
      end
    '
)

if ! NAME=$(
  fuzzel --dmenu \
    --prompt-only='   Rename workspace: ' \
    --search="$CURRENT_WORKSPACE_NAME" \
    --placeholder='(whitespace to unset)' \
    --width 35
); then
  exit 1
fi

if [ -z "$(printf %s "$NAME" | tr --delete '[:blank:]')" ]; then
  niri msg action unset-workspace-name
  swayosd-client --custom-message "Workspace name unset" --custom-icon "computer-symbolic"
else
  niri msg action set-workspace-name "$NAME"
  swayosd-client --custom-message "Workspace renamed to '$NAME'" --custom-icon "computer-symbolic"
fi
