{ config, lib, pkgs, ... }:

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
    if [ ! -e "$configDir/bibata-cursor.kdl" ]; then
      run install -m 644 ${pkgs.writeText "bibata-cursor.kdl" ''
        cursor { xcursor-theme "Bibata-Material-Ice-Blue"; }
      ''} "$configDir/bibata-cursor.kdl"
    fi
    if ! grep -Fqx 'include "bibata-cursor.kdl"' "$configDir/config.kdl"; then
      run sed -i '$a include "bibata-cursor.kdl"' "$configDir/config.kdl"
    fi
    installSeed ${./niri/dms/binds.kdl} "$configDir/dms/binds.kdl"

    # Seed the remaining includes only on first install; DMS owns them afterward.
    for fragment in alttab colors cursor layout outputs; do
      installSeed ${./niri/dms}/"$fragment.kdl" "$configDir/dms/$fragment.kdl"
    done
  '';
}
