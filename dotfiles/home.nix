{ config, inputs, lib, pkgs, ... }:

{
  home = {
    username = "ashgrey";
    homeDirectory = "/home/ashgrey";
    stateVersion = "26.05";
  };

  imports = [
    ./home/niri.nix
    ./home/dms.nix
    ./home/fcitx5.nix
    ./home/vim.nix
    ./home/fish.nix
  ];

  xdg.configFile."fastfetch/config.jsonc".source = ./home/fastfetch/config.jsonc;

  programs.home-manager.enable = true;

  # Keep Codex user skills in the dotfiles repository and expose them globally.
  home.file = lib.mapAttrs' (name: _:
    lib.nameValuePair ".agents/skills/${name}" {
      source = ./home/skills/${name};
      force = true;
    }
  ) (lib.filterAttrs (name: type:
    type == "directory"
    && builtins.pathExists (./home/skills + "/${name}/SKILL.md")
  ) (builtins.readDir ./home/skills));

  # Replace pre-existing copied skill directories with the managed links, but
  # only when their contents exactly match the repository copy. Keep a backup
  # under XDG state so activation never discards a user's differing files.
  home.activation.migrateCodexSkillDirectories = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    skillsSource=${lib.escapeShellArg (toString ./home/skills)}
    backupRoot=${lib.escapeShellArg "${config.xdg.stateHome}/home-manager/skill-backups"}
    for source in "$skillsSource"/*; do
      [ -d "$source" ] || continue
      [ -f "$source/SKILL.md" ] || continue
      name="$(basename "$source")"
      target=${lib.escapeShellArg "${config.home.homeDirectory}/.agents/skills"}/$name
      if [ -d "$target" ] && [ ! -L "$target" ]; then
        if ${pkgs.diffutils}/bin/diff -qr "$source" "$target" >/dev/null; then
          backup="$backupRoot/$name"
          if [ -e "$backup" ] || [ -L "$backup" ]; then
            echo "Cannot migrate $target: backup already exists at $backup" >&2
            exit 1
          fi
          run mkdir -p "$backupRoot"
          run mv "$target" "$backup"
        else
          echo "Cannot migrate $target: it differs from the managed skill in $source" >&2
          exit 1
        fi
      fi
    done
  '';

  # Steam expects its XDG data directory under ~/.local/share. Keep the actual
  # data in /var/lib/steam and expose only a symlink in the home directory.
  home.activation.steamDataOutsideHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    steamData=${lib.escapeShellArg "${config.home.homeDirectory}/.local/share/Steam"}
    steamTarget=/var/lib/steam/ashgrey/Steam
    run install -d -m 700 "$(dirname "$steamData")"
    if [ ! -e "$steamData" ] && [ ! -L "$steamData" ]; then
      run ln -s "$steamTarget" "$steamData"
    elif [ -L "$steamData" ] && [ "$(readlink "$steamData")" = "$steamTarget" ]; then
      :
    else
      echo "Keeping existing Steam data path: $steamData"
    fi
  '';

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  # Keep WeChat's default Documents entry as a link to user data, never the Nix store.
  home.activation.prepareWechatStorage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    wechatData=${lib.escapeShellArg "${config.xdg.dataHome}/wechat/xwechat_files"}
    wechatLink=${lib.escapeShellArg "${config.home.homeDirectory}/Documents/xwechat_files"}
    run install -d -m 700 "$wechatData"
    run mkdir -p "$(dirname "$wechatLink")"
    if [ ! -e "$wechatLink" ] && [ ! -L "$wechatLink" ]; then
      run ln -s "$wechatData" "$wechatLink"
    else
      echo "Keeping existing WeChat storage entry: $wechatLink"
    fi
  '';

  # DMS calls pywalfox when it regenerates the wallpaper palette.
  home.packages = [ pkgs.pywalfox-native ];

  xdg.desktopEntries.firefox = {
    name = "Firefox";
    genericName = "Web Browser";
    icon = "firefox";
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
    exec = "${pkgs.writeShellScript "firefox-with-stylus" ''
      if ! ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -x firefox >/dev/null; then
        exec /run/current-system/sw/bin/firefox "$@" "file://${config.xdg.configHome}/stylus/dms-web.user.css"
      fi
      exec /run/current-system/sw/bin/firefox "$@"
    ''} %U";
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      PS1='\[\e[36m\][\u@\h:\w]\$\[\e[0m\] '
    '';
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "application/pdf" = "org.kde.okular.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "x-scheme-handler/clash" = "clash-verge.desktop";
      "x-scheme-handler/clash-verge" = "clash-verge.desktop";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "ashgrey";
        email = "ashgrey.huaier@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      include = "${config.xdg.configHome}/kitty/matugen.conf";
      allow_remote_control = "socket-only";
      listen_on = "unix:$XDG_RUNTIME_DIR/kitty";
      # Kitty measures padding in points; 8pt is approximately 10px at the
      # current 1.25x display scale, matching the former 10px terminal padding.
      window_padding_width = "8 8";
      cursor_shape = "block";
      cursor_blink_interval = 0;
      shell_integration = "no-cursor";
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [ "~/.config/alacritty/dank-theme.toml" ];
      window = {
        opacity = 0.95;
        padding = {
          x = 10;
          y = 10;
        };
      };
      font = {
        size = 11.0;
        normal = {
          family = "monospace";
          style = "Regular";
        };
        bold = {
          family = "monospace";
          style = "Bold";
        };
      };
    };
  };
}
