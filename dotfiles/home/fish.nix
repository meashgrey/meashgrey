{ pkgs, ... }:

{
  # Keep user-installed tools such as uv tool scripts on PATH.
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.fish = {
    enable = true;
    generateCompletions = true;

    functions.fish_greeting = ''
      set_color cyan
      cat ${./fish/greeting.txt}
      set_color normal
    '';

    functions.nix-profile-delete = ''
      if test (count $argv) -eq 0
        echo "Usage: nix-profile-delete <generation-number> [generation-number ...]"
        return 2
      end

      for generation in $argv
        if not string match -rq '^[0-9]+$' -- "$generation"
          echo "Pass generation numbers from nix-profiles; this function does not accept 'old'." >&2
          return 2
        end
      end

      sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations $argv
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
      nix-profiles = "sudo nix-env --profile /nix/var/nix/profiles/system --list-generations";
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
