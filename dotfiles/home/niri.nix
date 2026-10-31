{ config, lib, ... }:

{
  # Seed missing files only. Niri and DMS keep ownership of existing files.
  home.activation.installNiriConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    configDir=${lib.escapeShellArg config.xdg.configHome}/niri
    run mkdir -p "$configDir/dms"

    installSeed() {
      sourceFile="$1"
      targetFile="$2"
      if [ ! -e "$targetFile" ] && [ ! -L "$targetFile" ]; then
        run install -m 644 "$sourceFile" "$targetFile"
      fi
    }

    installSeed ${./niri/config.kdl} "$configDir/config.kdl"
    installSeed ${./niri/dms/binds.kdl} "$configDir/dms/binds.kdl"

    # Seed the remaining includes only on first install; DMS owns them afterward.
    for fragment in alttab colors cursor layout outputs; do
      installSeed ${./niri/dms}/"$fragment.kdl" "$configDir/dms/$fragment.kdl"
    done
  '';
}
