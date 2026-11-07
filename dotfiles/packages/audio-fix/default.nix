{ writeShellApplication, alsa-utils, pipewire, pulseaudio, jq, coreutils }:

writeShellApplication {
  name = "audio-fix";
  runtimeInputs = [ alsa-utils pipewire pulseaudio jq coreutils ];
  text = builtins.readFile ./audio-fix.sh;
}
