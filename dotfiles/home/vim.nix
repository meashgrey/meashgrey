{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
  ];

  programs.vim = {
    enable = true;

    settings = {
      number = true;
    };

    extraConfig = ''
      set clipboard=unnamedplus
    '';
  };
}
