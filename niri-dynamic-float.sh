#!/usr/bin/env sh
# Requires jq

# RULES is a jq array of filters. Individual filter examples:
# > .example_property == "example string" or .ex_prop2 != "other string"
# > (.example_property | test("example_regex"))
# Filters should have commas between them

RULES='[
.app_id == "librewolf" and (.title | test(".*Bitwarden.*"))
]'

if jq --null-input --exit-status "$RULES | length == 0" >/dev/null; then
  >&2 echo 'At least 1 rule required in RULES'
  exit 1
fi

varset() {
  varname=$1
  val=$2
  eval "$varname=\"$val\""
}

varget() {
  varname=$1
  eval "printf %s \"\$$varname\""
}

getevent() {
  events=$1
  eventtype=$2

  # compact output for iterating by line later
  echo "$events" |
    jq --exit-status --compact-output "
    .$eventtype |
    select(. != null) |
    if isempty(.) then
      false
    else
      .windows.[]?, .window?, .id? | select(. != null)
    end
  "

  return $?
}

update_matched() {
  window=$1

  id=$(echo "$window" | jq .id)

  # WINDOWS_MATCHED_$id is true iff $id has been matched before
  matched_before=$(varget "WINDOWS_MATCHED_$id")
  : "${matched_before:=false}"

  matched=$(echo "$window" | jq "$RULES | any")

  # What to do when a matching window is found
  if [ "$matched" = true ] && [ "$matched_before" = false ]; then
    varset "WINDOWS_MATCHED_$id" true
    niri msg action move-window-to-floating --id "$id"
    niri msg action set-window-width --id "$id" 800
    niri msg action set-window-height --id "$id" 800
    niri msg action center-window --id "$id"
  fi
}

# disable globbing, split on newlines
set -f
NEWLINE='
'
IFS=$NEWLINE

# main loop, each line contains an event
niri msg --json event-stream | while read -r line; do
  # if there are any changed windows, then...
  if windows=$(getevent "$line" WindowsChanged); then
    # uses splitting on newlines to get individual $window out of $windows
    for window in $windows; do
      update_matched "$window"
    done
  # if there is a newly opened window, then...
  elif window=$(getevent "$line" WindowOpenedOrChanged); then
    update_matched "$window"
  # if a window was closed, then...
  elif id=$(getevent "$line" WindowClosed); then
    unset -v "WINDOWS_MATCHED_$id"
  fi
done
