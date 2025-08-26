#!/usr/bin/env sh

app2unit -- \
  foot --app-id=the-foot \
  sh -c '
    cbonsai --live --infinite \
      --message "Have lots of fun (press Super+? for keybinds)"
    zsh' &

# wait until window opens
niri msg -j event-stream |
  jq 'select(has("WindowOpenedOrChanged")).[] |
      .window |
      if .app_id == "the-foot" then
        halt
      end'

# TODO replace with some window ID strat to fullscreen instead of active window
THE_FOOT_ID=$(
  niri msg -j windows |
    jq '.[] | select(.app_id == "the-foot").id'
)

niri msg action move-window-to-workspace "" --window-id "$THE_FOOT_ID" --focus false
niri msg action fullscreen-window --id "$THE_FOOT_ID"
niri msg action focus-workspace-down
