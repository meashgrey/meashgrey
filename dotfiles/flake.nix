{
  description = "meashgrey's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    msime = {
      # Keep the currently locked MSIME source until explicitly upgraded.
      url = "github:metasequoiaime/msime/6ea397586c759e86367c38d0491f1d54a3a924d6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wetypex = {
      url = "github:panxuc/fcitx5-wetypex";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:duxlabs-dev/dux-shell/v1.6.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ferref = {
      url = "github:meashgrey/opensource-thosvarley__ferref/feat/tui-panel-resize";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, dms, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix
          inputs.msime.nixosModules.default

          home-manager.nixosModules.home-manager

          {
            nixpkgs.overlays = [
              nur.overlays.default
              (final: prev: {
                # The pinned nixpkgs 2.2.5 node_modules hash does not match
                # the output produced by Bun on this NixOS configuration.
                opencode = prev.opencode.overrideAttrs (old: {
                  node_modules = old.node_modules.overrideAttrs (_: {
                    outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
                  });
                });
              })
            ];

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.ashgrey = import ./home.nix;
            };
          }
        ];
      };
    };
}
