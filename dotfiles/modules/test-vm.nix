{ config, lib, pkgs, ... }:

let
  cfg = config.meashgrey.testVm;
in
{
  options.meashgrey.testVm.enable = lib.mkEnableOption
    "temporary desktop testing with QEMU/KVM and libvirt";

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    users.users.ashgrey.extraGroups = [ "libvirtd" ];

    # Explicit CLI tools for agents, plus a graphical guest console.
    environment.systemPackages = with pkgs; [
      libvirt
      virt-viewer
    ];
  };
}
