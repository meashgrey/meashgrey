{ lib, pkgs, ... }:
let
  audioFix = pkgs.callPackage ../packages/audio-fix { };
in
{
  environment.systemPackages = [ audioFix ];

  # Persistence alone cannot repair a saved state with both DAC paths muted.
  # Apply the known-good switches after ALSA has restored its saved state.
  systemd.services.es8336-audio-fix = {
    description = "Restore ES8336 DAC playback paths";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" "alsa-store.service" ];
    unitConfig.ConditionPathExists = "/proc/asound/sofessx8336";
    serviceConfig.Type = "oneshot";
    script = ''
      ${lib.getExe audioFix} --hardware-only
      ${pkgs.alsa-utils}/bin/alsactl store -gU
    '';
  };

  # Repair codec switches reset by suspend without switching away from a
  # Bluetooth headset or changing the user's volume and microphone settings.
  powerManagement.resumeCommands = ''
    if [ -e /proc/asound/sofessx8336 ]; then
      ${lib.getExe audioFix} --hardware-only
    fi
  '';
}
