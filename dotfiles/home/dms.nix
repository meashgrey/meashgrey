{ config, lib, pkgs, inputs, ... }:

let
  bibataThemes = import ./dms/bibata-cursors.nix { inherit pkgs; };
  cursorHook = pkgs.writeShellScript "dms-bibata-cursor" ''
    set -eu
    color="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg "${config.xdg.configHome}/matugen/bibata-color"})"
    name="$(${pkgs.python3}/bin/python3 ${./dms/bibata-color-match.py} "$color" ${./dms/bibata-themes.json})"
    theme="Bibata-Material-$name"
    file=${lib.escapeShellArg "${config.xdg.configHome}/niri/bibata-cursor.kdl"}
    tmp="$(${pkgs.coreutils}/bin/mktemp "$file.XXXXXX")"
    printf 'cursor {\n    xcursor-theme "%s"\n}\n' "$theme" > "$tmp"
    ${pkgs.coreutils}/bin/mv -f "$tmp" "$file"
    cursor_dir=${lib.escapeShellArg "${config.home.homeDirectory}/.icons/default"}
    cursor_index="$cursor_dir/index.theme"
    ${pkgs.coreutils}/bin/mkdir -p "$cursor_dir"
    if [ ! -e "$cursor_index" ] && [ ! -L "$cursor_index" ] ||
       { [ -f "$cursor_index" ] && [ ! -L "$cursor_index" ] && ${pkgs.gnugrep}/bin/grep -Fxq 'Comment=Managed by DMS Bibata' "$cursor_index"; }; then
      cursor_tmp="$(${pkgs.coreutils}/bin/mktemp "$cursor_dir/index.theme.XXXXXX")"
      printf '[Icon Theme]\nName=Default\nComment=Managed by DMS Bibata\nInherits=%s\n' "$theme" > "$cursor_tmp"
      ${pkgs.coreutils}/bin/mv -f "$cursor_tmp" "$cursor_index"
    else
      echo "Preserving existing cursor default: $cursor_index" >&2
    fi
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme "$theme" || true
  '';
in {
  home.packages = [ bibataThemes ];
  dconf.settings."org/gnome/desktop/interface".gtk-theme = "adw-gtk3";

  systemd.user.services.dms-gtk-colors = {
    Unit = {
      Description = "Apply DMS colors to GTK themes";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "apply-dms-gtk-colors" ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.glib pkgs.bash ]}:"$PATH"
        if [ -f ${lib.escapeShellArg "${config.xdg.configHome}/gtk-4.0/dank-colors.css"} ]; then
          script=${inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/quickshell/dms/scripts/gtk.sh
          "$script" ${lib.escapeShellArg config.xdg.configHome} apply
          mode="$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface color-scheme || true)"
          light=false
          case "$mode" in *prefer-light*) light=true;; esac
          "$script" ${lib.escapeShellArg config.xdg.configHome} patch "$light"
        fi
      '';
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
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

  # Keep desktop-managed settings writable while adding DMS color integration.
  home.activation.configureDmsAppColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${./dms/configure-app-colors.py} \
      ${lib.escapeShellArg config.xdg.configHome}

    # KDE Frameworks apps (including Okular) read their active scheme from kdeglobals.
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kdeglobals --group General --key ColorScheme DankMatugen
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
