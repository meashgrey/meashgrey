# Target the card by its stable ALSA ID, not the changing card/node numbers.
export LC_ALL=C
card=sofessx8336
mode=repair
case "${1:-}" in
  --check) mode=check ;;
  --hardware-only) mode=hardware ;;
  --help|-h)
    printf '%s\n' 'audio-fix                 Repair ES8336 hardware and select laptop speakers.' \
      'audio-fix --check         Inspect hardware and audio routing without changes.' \
      'audio-fix --hardware-only Repair only DAC switches (boot/resume hook).'
    exit 0
    ;;
  '') ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
  printf 'Expected at most one option; see audio-fix --help.\n' >&2
  exit 2
fi

if ! amixer -c "$card" info >/dev/null 2>&1; then
  printf 'ES8336 card not found or inaccessible. Check /proc/asound/cards and device permissions.\n' >&2
  exit 1
fi

healthy=true
for control in 'Left Headphone Mixer Left DAC Switch' 'Right Headphone Mixer Right DAC Switch'; do
  value=$(amixer -c "$card" cget "name=$control")
  if [[ "$value" == *'values=on'* ]]; then
    printf 'OK: %s = on\n' "$control"
  elif [[ "$mode" == check ]]; then
    printf 'FAULT: %s = off\n' "$control"
    healthy=false
  else
    amixer -c "$card" cset "name=$control" on >/dev/null
    value=$(amixer -c "$card" cget "name=$control")
    if [[ "$value" != *'values=on'* ]]; then
      printf 'Failed to enable %s\n' "$control" >&2
      exit 1
    fi
    printf 'FIXED: %s = on\n' "$control"
  fi
done

if [[ "$mode" == hardware ]]; then
  exit 0
fi
if [[ $EUID == 0 ]]; then
  printf 'Run without sudo to access your PipeWire session. Hardware switches have been checked.\n' >&2
  exit 1
fi

# Bound inspection time if the audio server is unresponsive. Leave service
# restarts to the user: restarting would interrupt games, calls and recordings.
snapshot=$(timeout 8 pw-dump) || {
  printf 'Cannot query PipeWire. Try: systemctl --user restart pipewire pipewire-pulse wireplumber\n' >&2
  exit 1
}
speaker=$(jq -r --arg card "$card" '
  [.[] | select(.type == "PipeWire:Interface:Node") | .info.props
   | select(."media.class" == "Audio/Sink" and ."alsa.id" == $card)
   | select(."device.profile.description" == "Speakers") | ."node.name"]
  | if length == 1 then .[0] else empty end
' <<< "$snapshot")
if [[ -z "$speaker" ]]; then
  printf 'Speaker output is missing or ambiguous. Check the sound card profile with wpctl status.\n' >&2
  exit 1
fi

if [[ "$mode" == check ]]; then
  printf '\nSpeaker: %s\n' "$speaker"
  timeout 8 pactl get-default-sink
  timeout 8 pactl get-sink-mute "$speaker"
  timeout 8 pactl get-sink-volume "$speaker"
  if [[ "$(timeout 8 pactl get-sink-mute "$speaker")" != 'Mute: no' ]]; then
    healthy=false
  fi
  if ! timeout 8 pactl --format=json list sinks | jq -e --arg name "$speaker" \
    'any(.[]; .name == $name and any(.volume[]; .value > 0))' >/dev/null; then
    healthy=false
  fi
  if [[ "$healthy" != true ]]; then
    printf '\nFault detected. Run audio-fix to repair.\n' >&2
    exit 1
  fi
  printf '\nHardware switches and speaker volume are OK; audible output still needs a listening check.\n'
  exit 0
fi

timeout 8 pactl set-default-sink "$speaker"
timeout 8 pactl set-sink-mute "$speaker" 0
if ! timeout 8 pactl --format=json list sinks | jq -e --arg name "$speaker" \
  'any(.[]; .name == $name and any(.volume[]; .value > 0))' >/dev/null; then
  timeout 8 pactl set-sink-volume "$speaker" 40%
fi
# Move existing playback too, including a game that started before the repair.
inputs=$(timeout 8 pactl --format=json list sink-inputs)
while IFS= read -r stream; do
  if ! timeout 8 pactl move-sink-input "$stream" "$speaker"; then
    printf 'Could not move playback stream %s (it may have closed).\n' "$stream" >&2
  fi
done < <(jq -r '.[].index' <<< "$inputs")
printf '\nSpeakers selected and unmuted; existing playback routed to them.\n'
printf 'Play audio to confirm. This command does not change microphone settings.\n'
