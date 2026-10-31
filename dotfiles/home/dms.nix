{ config, lib, ... }:

{
  # Install defaults only if no user configuration exists.
  home.activation.installDmsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    configDir=${lib.escapeShellArg config.xdg.configHome}/DankMaterialShell
    targetFile="$configDir/settings.json"
    run mkdir -p "$configDir"
    if [ ! -e "$targetFile" ] && [ ! -L "$targetFile" ]; then
      run install -m 644 ${./dms/settings.json} "$targetFile"
    fi
  '';
}
