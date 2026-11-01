{ config, lib, pkgs, ... }:

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

  programs.home-manager.enable = true;

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
    settings.user = {
      name = "ashgrey";
      email = "ashgrey.huaier@gmail.com";
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
          family = "Cascadia Code";
          style = "Regular";
        };

        bold = {
          family = "Cascadia Code";
          style = "Bold";
        };
      };
    };
  };
}
