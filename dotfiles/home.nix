{ config, pkgs, ... }:

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
  };

  programs.alacritty = {
    enable = true;

    settings = {
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
