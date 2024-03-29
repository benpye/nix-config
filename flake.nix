{
  description = "Nix configuration flake.";

  inputs = {
    # Unstable channels
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable release channels
    nixpkgs-2111.url = "github:nixos/nixpkgs/release-21.11";
    nixos-2111.url = "github:nixos/nixpkgs/nixos-21.11";

    nixpkgs-2205.url = "github:nixos/nixpkgs/release-22.05";
    nixos-2205.url = "github:nixos/nixpkgs/nixos-22.05";

    nixpkgs-2211.url = "github:nixos/nixpkgs/release-22.11";
    nixos-2211.url = "github:nixos/nixpkgs/nixos-22.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    launchd_shim = {
      url = "github:benpye/launchd_shim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hkrm4 = {
      url = "github:benpye/hkrm4";
      inputs.nixpkgs.follows = "nixos-2211";
    };

    nix-fpga-tools.url = "github:benpye/nix-fpga-tools";

    flake-utils.url = "github:numtide/flake-utils";

    nix-velocloud = {
      url = "github:benpye/nix-velocloud";
      inputs.nixos.follows = "nixos-2211";
    };
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

      nixtop = {
        home-manager = inputs.home-manager;
        system = "x86_64-linux";
        stateVersion = "21.11";
        username = "ben";
        homeDirectory = "/home/ben";
        overlays = [ inputs.nix-fpga-tools.overlay ];
      };
    };

    nixosConfigurations = lib.mkNixosConfigurations {
      nixserve = {
        nixos = inputs.nixos-2211;
        system = "x86_64-linux";
        overlays = [
          (self: super: { unstable = inputs.nixpkgs.legacyPackages.x86_64-linux; })
          inputs.hkrm4.overlay
        ];
      };

      nixtop = {
        nixos = inputs.nixos;
        system = "x86_64-linux";
        overlays = [ inputs.nix-fpga-tools.overlay ];
      };

      routenix = {
        nixos = inputs.nixos-2211;
        system = "x86_64-linux";
        overlays = [ inputs.nix-velocloud.overlay ];
      };

      nixblaster = {
        nixos = inputs.nixos-2205;
        system = "aarch64-linux";
      };
    };

  } // inputs.flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ (import ./pkgs) ] ++ (import ./overlays);
    };
  in
  {
    packages = pkgs // inputs.flake-utils.lib.flattenTree {
      # Export nixos-rebuild package with unstable nix for flakes.
      nixos-rebuild = pkgs.nixos-rebuild.override { nix = pkgs.nixUnstable; };
    };
  });
}
