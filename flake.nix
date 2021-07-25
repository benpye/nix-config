{
  description = "Nix configuration flake.";

  inputs = {
    # Unstable channels
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable release channels
    nixpkgs-2009.url = "github:nixos/nixpkgs/release-20.09";
    nixos-2009.url = "github:nixos/nixpkgs/nixos-20.09";

    nixpkgs-2105.url = "github:nixos/nixpkgs/release-21.05";
    nixos-2105.url = "github:nixos/nixpkgs/nixos-21.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    launchd_shim = {
      url = "github:benpye/launchd_shim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:benpye/flake-utils/add-aarch64-darwin-as-default";
  };

  outputs = inputs@{ self, ... }:
  let
    lib = import ./lib {};
  in
  {
    homeConfigurations = lib.mkHomeConfigurations {
      m1pro = {
        home-manager = inputs.home-manager;
        system = "aarch64-darwin";
        stateVersion = "21.05";
        username = "benpye";
        homeDirectory = "/Users/benpye";
        overlays = [ inputs.launchd_shim.overlay ];
      };
    };

    nixosConfigurations = lib.mkNixosConfigurations {
      nixserve = {
        nixos = inputs.nixos-2105;
        system = "x86_64-linux";
        overlays = [
          (self: super: { unstable = inputs.nixpkgs.legacyPackages.x86_64-linux; })
        ];
      };

      nixbuild = {
        nixos = inputs.nixos-2009;
        system = "x86_64-linux";
      };
    };

  } // inputs.flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = inputs.nixpkgs.legacyPackages.${system};
  in
  {
    packages = inputs.flake-utils.lib.flattenTree {
      # Export nixos-rebuild package with unstable nix for flakes.
      nixos-rebuild = pkgs.nixos-rebuild.override { nix = pkgs.nixUnstable; };
    };
  });
}
