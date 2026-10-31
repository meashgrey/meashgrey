{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    generateCompletions = true;

    functions.fish_greeting = ''
      set_color cyan
      cat ${./fish/greeting.txt}
      set_color normal
    '';

    interactiveShellInit = ''
      set -g fish_color_cwd cyan
      set -g fish_color_user cyan
    '';

    shellAbbrs = {
      nr = "sudo nixos-rebuild";
      nrb = "sudo nixos-rebuild build --flake /etc/nixos#nixos";
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";

      ".." = "cd ..";
      "..." = "cd ../..";
    };

    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
    };

    shellInit = ''
      set -gx HTTP_PROXY "http://127.0.0.1:7897";
      set -gx HTTPS_PROXY "http://127.0.0.1:7897";
    '';
  };

  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    ripgrep
    zoxide
    wl-clipboard
  ];
}
