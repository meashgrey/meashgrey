{ config, lib, pkgs, ... }:

let
  bibataArchive = pkgs.fetchurl {
    url = "https://github.com/SakibShahariar/material-bibata-cursor/releases/download/v1.5.0/bibata-material-dark-v1.5.0.tar.gz";
    hash = "sha256-igz93WB4fGWgeM5JS1cIwdaPPldhGP3gcBlJ7bQMugQ=";
  };
  bibataThemes = pkgs.runCommand "material-bibata-cursors-1.5.0" {} ''
    mkdir -p "$out/share/icons"
    tar -xzf ${bibataArchive} --strip-components=1 -C "$out/share/icons"
  '';
  cursorHook = pkgs.writeShellScript "dms-bibata-cursor" ''
    set -eu
    color="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg "${config.xdg.configHome}/matugen/bibata-color"})"
    name="$(${pkgs.python3}/bin/python3 ${./dms/bibata-color-match.py} "$color" ${./dms/bibata-themes.json})"
    theme="Bibata-Material-$name"
    file=${lib.escapeShellArg "${config.xdg.configHome}/niri/bibata-cursor.kdl"}
    tmp="$(${pkgs.coreutils}/bin/mktemp "$file.XXXXXX")"
    printf 'cursor {\n    xcursor-theme "%s"\n}\n' "$theme" > "$tmp"
    ${pkgs.coreutils}/bin/mv -f "$tmp" "$file"
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme "$theme" || true
  '';
in {
  home.packages = [ bibataThemes ];
  xdg.configFile."matugen/config.toml".text = ''
    [config]
    [templates.stylus]
    input_path = '${config.xdg.configHome}/matugen/templates/dms-web.user.css'
    output_path = '${config.xdg.configHome}/stylus/dms-web.user.css'

    [templates.bibata]
    input_path = '${config.xdg.configHome}/matugen/templates/bibata-color.txt'
    output_path = '${config.xdg.configHome}/matugen/bibata-color'
    post_hook = '${cursorHook}'
  '';
  xdg.configFile."matugen/templates/dms-web.user.css".source = ./dms/dms-web.user.css;
  xdg.configFile."matugen/templates/bibata-color.txt".text = "{{colors.primary.default.hex}}";

  home.activation.createStylusThemeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/stylus"}
  '';

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
