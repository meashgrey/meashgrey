# Configuration used for meashgrey

{ inputs, lib, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # home-manager configurations

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball {
      url = "https://github.com/nix-community/NUR/archive/main.tar.gz";
    }) {
      inherit pkgs;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ashgrey = import ./home.nix;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Test the newest kernel available in the locked nixpkgs for ES8336 audio.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Nix daemon downloads do not inherit the desktop user's shell environment.
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://127.0.0.1:7897";
    https_proxy = "http://127.0.0.1:7897";
    no_proxy = "127.0.0.1,localhost,::1";
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  # When it needs to login with American time zone, decomment this
  # time.timeZone = "America/Chicago";
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-mozc
        fcitx5-rime
        fcitx5-gtk
        (inputs.wetypex.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-wetypex.override {
          enableWeTypeTheme = false;
        })
      ];
      settings.inputMethod = {
        GroupOrder."0" = "Default";

        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "msime";
        };

        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "msime";
        "Groups/0/Items/2".Name = "pinyin";
        "Groups/0/Items/3".Name = "rime";
        "Groups/0/Items/4".Name = "mozc";
      };
    };
  };

  programs.msime.enable = true;
  programs.dconf.enable = true;

  # Keep Steam's persistent client data and default game library under /var/lib,
  # outside the user's home directory.
  programs.steam.enable = true;
  # UMU's pressure-vessel tools are generic Linux binaries. Provide the ELF
  # loader and libraries they expect on NixOS.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      glib
      libXau
      json-glib
      elfutils
    ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/steam/ashgrey/Steam 0700 ashgrey users -"
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Install the Qt5 and Qt6 platform plugins used by DMS's qtct themes.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = false;
  services.desktopManager.plasma6.enable = false;

  # Use Dux Greeter (formerly DMS Greeter) with Niri instead of LightDM.
  services.xserver.displayManager.lightdm.enable = false;
  services.displayManager.dux-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/ashgrey";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # Keep the ES8336 DAC mixer switches enabled across boots.
  hardware.alsa.enablePersistence = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."ashgrey" = {
    isNormalUser = true;
    description = "meashgrey";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.okular
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.firefox.nativeMessagingHosts.packages = [
    (pkgs.writeTextFile {
      name = "pywalfox-native-messaging-host";
      destination = "/lib/mozilla/native-messaging-hosts/pywalfox.json";
      text = builtins.toJSON {
        name = "pywalfox";
        description = "Pywalfox native messaging host";
        path = "${pkgs.pywalfox-native}/bin/pywalfox";
        type = "stdio";
        allowed_extensions = [ "pywalfox@frewacom.org" ];
      };
    })
  ];

  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    serviceMode = true;
    tunMode = true;
    group = "wheel";
  };

  programs.niri.enable = true;
  programs.yazi.enable = true;
  programs.fish.enable = true;

  # System defaults; Codex can write user preferences to ~/.codex/config.toml.
  environment.etc."codex/config.toml".source =
    (pkgs.formats.toml { }).generate "codex-config.toml" {
      approval_policy = "on-request";
      sandbox_mode = "workspace-write";
      sandbox_workspace_write.network_access = false;
      tui.status_line = [ "git-branch" "five-hour-limit" "weekly-limit" ];
    };

  programs.dux-shell = {
    enable = true;
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  users.users.ashgrey.shell = pkgs.fish;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Mirror websites
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
    "https://cache.nixos.org"
  ];

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    (import ./home/dms/bibata-cursors.nix { inherit pkgs; })
    (callPackage ./packages/steam-tui { })
    inputs.ferref.packages.${pkgs.stdenv.hostPlatform.system}.default
    vim
    wget
    appimage-run
    codex
    vscodium
    (symlinkJoin {
      name = "wechat-cursor-size";
      paths = [ wechat ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/wechat" --set XCURSOR_SIZE 22
      '';
    })
    adw-gtk3
    # GTK currently selects breeze; make the theme available to DMS as well.
    kdePackages.breeze-icons

    # shell tools
    nushell
    alacritty
    # Niri uses this to provide X11 compatibility for Steam and other XWayland apps.
    xwayland-satellite
    tmux
    dust
    bottom
    btop
    fzf
    zoxide
    navi
    doxx
    fastfetch
    onefetch
    lazygit

    # Long-lived development tools
    opencode
    bun
    nodejs_22
    (callPackage ./packages/wordcraft { })
    python3
    uv
    touying
    gcc
    rustc
    cargo
    typst
    poppler-utils
  ];

  # Make the installed cursor theme discoverable to XWayland's Xcursor loader.
  environment.sessionVariables.XCURSOR_PATH = [
    "/run/current-system/sw/share/icons"
    "/usr/share/icons"
    "/usr/share/pixmaps"
  ];

  fonts.packages = with pkgs; [
    cascadia-code
    noto-fonts-color-emoji
    libertinus
    lxgw-wenkai
  ];

  fonts.fontconfig.defaultFonts.emoji = [ "Noto Color Emoji" ];
  fonts.fontconfig.defaultFonts.monospace = [
    "Cascadia Code"
    "emoji"
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
