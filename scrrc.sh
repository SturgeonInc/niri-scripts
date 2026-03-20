#!/usr/bin/env sh
# is a wl-screenrec wrapper
# also requires jq, notify-send, fuzzel

set -e

DEFAULT_FILENAME="screenrecording-$(date --iso-8601=seconds)"
NOTIFICATION_HEADER='Screen Recording'
NOTIFICATION_ICON='record-screen-symbolic'

notify() {
  notify-send --icon="$NOTIFICATION_ICON" "$NOTIFICATION_HEADER" "$@"
}
usage() {
  >&2 cat <<EOF
Usage: $(basename "$0") [OPTIONS] -- SCREENREC_OPTS...
Screen recorder wrapper script. Offers notification actions to provide a minimal
GUI to stop, pause, and resume recording. You can also do this manually by just
SIGINT'ing the command, or on a keybind by pkill'ing wl-screenrec.

E.g. config: 
Mod+Control+Shift+S { spawn-sh "pkill wl-screenrec || $(basename "$0") --audio"; }

OPTIONS:
  -h, --help               Show this message
  -a, --audio              Include audio. Uses a fuzzel menu to pick audio device
                           since I've had bad experiences with the raw --audio opt;
                           best to use a *.monitor device. Esc'ing out of picker will
                           proceed with no audio instead
  -o, --output             File/Dir to write to. Defaults to 
                           \$HOME/Videos/Screen Recordings/screenrecording-ISODATE.mkv
  -f, --format             Recording format, as a file suffix. Overwritten by -o.
                           Warning: these may require fiddling with codec settings
                           try ' -- --no-hw'
  -n, --no-ui              No UI notifications. Recording must be ended manually
                           Either way, you can pkill wl-screenrec
  -s, --no-select          Don't select display geometry
  -u, --no-ui              Don't show the notifications with the pause/play/stop actions
  SCREENREC_OPTS...        These get passed to wl-screenrec directly
EOF
}

opts=$(
  getopt --name "$(basename "$0")" \
    --shell sh \
    --options o:f:usha \
    --longoptions output:format:no-ui,no-select,help,audio \
    -- "$@"
)
eval "set -- $opts"

for _ in $(seq $#); do
  case "$1" in
  -h | --help)
    usage
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
  -a | --audio)
    AUDIO=1
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
: "${AUDIO:=0}"
: "${OUTPUT_FORMAT:=mkv}"
: "${SCREENREC_DIR="$HOME/Videos/Screen Recordings"}"
: "${SCREENREC_FILE:="$SCREENREC_DIR/$DEFAULT_FILENAME.$OUTPUT_FORMAT"}"

if pidof wl-screenrec; then
  >&2 echo "wl-screenrec already running"
  notify-send "$NOTIFICATION_HEADER" 'Screen recording failed: ' \
    'another screen recording is in progress'
  exit 1
fi

if [ "$SELECT" -eq 1 ]; then
  # -d for dimension; -o for fullscreen default
  output=$(slurp -d -o) || exit
  select_opt="--geometry='$output'"
fi
if [ "$UI" -eq 1 ]; then
  exec_opt='&'
else
  exec_opt='; exit'
fi
if [ "$AUDIO" -eq 1 ]; then
  stream_idx=$(
    pactl --format='json' list sources short |
      jq '.[] | (.index | tostring) + "\t" + .name' \
        --raw-output0 |
      fuzzel --placeholder='Choose audio device (recommended: *.monitor)' \
        --accept-nth='1' --with-nth='2' \
        --minimal-lines \
        --dmenu0
  ) &&
    audio_device=$(
      pactl --format='json' list sources short |
        jq --raw-output ".[] | select(.index == $stream_idx) | .name"
    ) &&
    audio_opt="--audio --audio-device='$audio_device'" ||
    AUDIO=0
fi

eval wl-screenrec \
  "--filename '$SCREENREC_FILE'" \
  "$audio_opt" \
  "$select_opt" \
  "$*" \
  " $exec_opt"
recording_p=$!

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
    PAUSE) command kill -STOP "$recording_p" ;;
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
    RESUME) command kill -CONT "$recording_p" ;;
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

  command kill -CONT "$recording_p"
  command kill "$recording_p"
) &
loop_p=$!

wait "$recording_p"

notify "Screen recording saved to '$SCREENREC_FILE'" \
  --replace-id="$ID"
ps -p "$loop_p" && command kill "$loop_p"
command kill -KILL "$loop_p"
