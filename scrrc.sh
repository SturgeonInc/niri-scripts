#!/usr/bin/env sh

set -e

DEFAULT_FILENAME="screenrecording-$(date --iso-8601=seconds)"
NOTIFICATION_HEADER='Screen Recording'
NOTIFICATION_ICON='record-screen-symbolic'

notify() {
  notify-send --icon="$NOTIFICATION_ICON" "$NOTIFICATION_HEADER" "$@"
}

opts=$(
  getopt --name "$(basename "$0")" \
    --shell sh \
    --options o:f:nsh \
    --longoptions output:format:no-ui,no-select,help \
    -- "$@"
)
eval "set -- $opts"

for _ in $(seq $#); do
  case "$1" in
  -h | --help)
    >&2 cat <<EOF
Usage: $(basename "$0") [OPTIONS] -- SCREENREC_OPTS...
  -h, --help               Show this message
  -o, --output             File/Dir to write to. Defaults to 
                           \$HOME/Videos/Screen Recordings/screenrecording-ISODATE.mkv
  -f, --format             Recording format, as a file suffix. Overwritten by -o.
                           Warning: these may require fiddling with codec settings
                           try ' -- --no-hw'
  -n, --no-ui              No UI notifications. Recording must be ended manually
  -s, --no-select          Don't select display geometry
  SCREENREC_OPTS...        These get passed to wl-screenrec directly
EOF
    exit
    ;;
  -o | --output)
    if [ "$(basename "$2")" = "$2" ]; then
      SCREENREC_FILE="$SCREENREC_DIR/$2"
    elif [ -d "$2" ]; then
      SCREENREC_DIR="$2"
    fi
    shift
    ;;
  -f | --format) # ignored if -o is specified
    OUTPUT_FORMAT=$2
    shift
    ;;
  -u | --no-ui)
    UI=0
    ;;
  -s | --no-select)
    SELECT=0
    ;;
  --)
    shift
    break
    ;;
  *)
    >&2 echo "Unrecognized option. Exiting"
    exit 1
    ;;
  esac
  shift
done

: "${SELECT:=1}"
: "${UI:=1}"
: "${OUTPUT_FORMAT:=mkv}"
: "${SCREENREC_DIR="$HOME/Videos/Screen Recordings"}"
: "${SCREENREC_FILE:="$SCREENREC_DIR/$DEFAULT_FILENAME.$OUTPUT_FORMAT"}"

if pidof wl-screenrec; then
  >&2 echo "wl-screenrec already running"
  notify-send "$NOTIFICATION_HEADER" 'Screen recording failed: ' \
    'another screen recording is in progress'
  exit 1
fi

# -d for dimension; -o for fullscreen default
if [ "$SELECT" -eq 1 ]; then
  output=$(slurp -d -o) || exit
  wl-screenrec --geometry="$output" \
    --filename "$SCREENREC_FILE" \
    "$@" &
else
  wl-screenrec \
    --filename "$SCREENREC_FILE" \
    "$@" &
fi
recording_p=$!

# exit with job instead of using notification UI
if [ "$UI" -eq 0 ]; then
  fg
  exit $?
fi

if ! ps --pid "$recording_p"; then
  >&2 echo "Screen recording failed"
  notify-send "$NOTIFICATION_HEADER" 'Screen recording failed'
  exit 1
fi

ID=$(notify-send "$NOTIFICATION_HEADER" --print-id)

(
  ACTION=$(
    notify 'Screen is being recording, dismiss to end' \
      --action='PAUSE'='Pause recording' \
      --action='END'='End recording' \
      --urgency='critical' \
      --replace-id="$ID"
  )

  while true; do

    case "$ACTION" in
    PAUSE) command kill -s STOP "$recording_p" ;;
    *) break ;;
    esac
    >&2 echo PAUSE

    ACTION=$(
      notify 'Recording is paused' \
        --action='RESUME'='Resume Recording' \
        --action='END'='End recording' \
        --urgency='critical' \
        --replace-id="$ID"
    )

    case "$ACTION" in
    RESUME) command kill -s CONT "$recording_p" ;;
    *) break ;;
    esac
    >&2 echo RESUME

    ACTION=$(
      notify 'Recording resumed' \
        --action='PAUSE'='Pause recording' \
        --action='END'='End recording' \
        --urgency='critical' \
        --replace-id="$ID"
    )
  done

  kill -s CONT "$recording_p"
  kill "$recording_p"
) &
loop_p=$!

wait "$recording_p"

ps -p "$loop_p" || command kill "$loop_p"
notify "Screen recording saved to '$SCREENREC_FILE'" \
  --replace-id="$ID"
exit
