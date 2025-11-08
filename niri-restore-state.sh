#!/usr/bin/env sh

NIRI_STATE_FILE="$HOME/.niri-state.json"

unset_list=
unset_list=$(
  cat "$NIRI_STATE_FILE" |
    # in niri you can only rename workspaces that exist. So goes in index order
    # to spawn in later indices as it counts up
    jq --compact-output '.workspaces | sort_by(.idx) | .[]' |
    while read -r line; do
      ws_idx=$(echo "$line" | jq '.idx')

      # Must give all workspaces names to generate subsequent ones
      # so must unset these later. They're numbers, so safe to split by white
      # space later in the set statement.
      if
        ! ws_name=$(echo "$line" | jq --exit-status --raw-output '.name')
      then
        echo "$ws_idx"
        ws_name=$ws_idx
      fi

      niri msg action set-workspace-name --workspace "$ws_idx" "$ws_name"
    done
)

# TODO: RESTORE WINDOWS TO INDICES HERE BEFORE WE UNSET THE NAMES

# shellcheck disable=SC2046 # Want this to split
# Also want to start from last index so that indices don't get screwed up if
# niri prunes any empty nameless workspaces during this process
set -- $(echo "$unset_list" | sort --reverse)
for idx in "$@"; do
  niri msg action unset-workspace-name "$idx"
done
