# ES8336 speaker recovery

`audio-fix` repairs the two ES8336 DAC mixer switches, selects the laptop
speakers, unmutes them and moves existing PulseAudio-compatible playback streams
to them. A zero speaker volume is raised to 40%; an existing nonzero volume is
preserved. Run it as the logged-in user, without sudo.

```sh
audio-fix
audio-fix --check
```

`--check` is read-only and returns a nonzero status for disabled DAC paths,
muted/zero-volume speakers or inaccessible audio services. It reports the default
output separately; a Bluetooth default is not itself considered a fault. A
successful check confirms software state, not audible output or hardware health.

The NixOS module in `../../modules/audio-fix.nix` installs the command and fixes
the DAC paths after ALSA state restoration at boot and on resume. These automatic
hooks do not change the selected output, volume or microphone. They take effect
after switching to the updated NixOS configuration. Manual repair works as soon
as the package is installed.

The utility targets ALSA card ID `sofessx8336`, so it does not depend on numeric
card or PipeWire node IDs. It does not restart audio services or reset Bluetooth
pairings. Missing devices and unresponsive services are reported instead of
silently resetting them.
