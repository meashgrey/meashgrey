{ config, lib, ... }:

{
  xdg.configFile."matugen/config.toml".text = ''
    [config]
    [templates.stylus]
    input_path = '${config.xdg.configHome}/matugen/templates/dms-web.user.css'
    output_path = '${config.xdg.configHome}/stylus/dms-web.user.css'
  '';
  xdg.configFile."matugen/templates/dms-web.user.css".source = ./dms/dms-web.user.css;

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
