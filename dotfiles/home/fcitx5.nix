{ config, lib, ... }:

{
  # Fcitx5 writes its profile; seed it only when no profile exists.
  home.activation.installFcitx5Profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    configDir=${lib.escapeShellArg config.xdg.configHome}/fcitx5
    targetFile="$configDir/profile"
    run mkdir -p "$configDir"
    if [ ! -e "$targetFile" ] && [ ! -L "$targetFile" ]; then
      run install -m 600 ${./fcitx5/profile} "$targetFile"
    fi
  '';
}
