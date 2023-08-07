{
  description = "Nix configuration flake.";

  inputs = {
    # Unstable channels
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable release channels
    nixpkgs-2311.url = "github:nixos/nixpkgs/release-23.11";
    nixos-2311.url = "github:nixos/nixpkgs/nixos-23.11";

    nixpkgs-2305.url = "github:nixos/nixpkgs/release-23.05";
    nixos-2305.url = "github:nixos/nixpkgs/nixos-23.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    launchd_shim = {
      url = "github:benpye/launchd_shim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mi2mqtt = {
      url = "github:benpye/mi2mqtt";
      inputs.nixpkgs.follows = "nixos-2311";
    };

    hkrm4 = {
      url = "github:benpye/hkrm4";
      inputs.nixpkgs.follows = "nixos-2311";
    };

    nix-fpga-tools.url = "github:benpye/nix-fpga-tools";

    flake-utils.url = "github:numtide/flake-utils";

    nix-velocloud = {
      url = "github:benpye/nix-velocloud";
      inputs.nixos.follows = "nixos-2311";
    };
  };

  outputs = inputs@{ self, ... }:
  let
    lib = import ./lib {};
  in
  {
    homeConfigurations = lib.mkHomeConfigurations {
      # MacBook
      m1pro = {
        home-manager = inputs.home-manager;
        system = "aarch64-darwin";
        stateVersion = "21.05";
        username = "benpye";
        homeDirectory = "/Users/benpye";
        overlays = [ inputs.launchd_shim.overlay ];
      };

      # Desktop
      hydrogen = {
        home-manager = inputs.home-manager;
        system = "x86_64-linux";
        stateVersion = "23.11";
        username = "ben";
        homeDirectory = "/home/ben";
        overlays = [ ];
      };
    };

    nixosConfigurations = lib.mkNixosConfigurations {
      # Desktop
      hydrogen = {
        nixos = inputs.nixos;
        system = "x86_64-linux";
        overlays = [ inputs.nix-fpga-tools.overlay ];
      };

      # Home server
      nixserve = {
        nixos = inputs.nixos-2311;
        system = "x86_64-linux";
        overlays = [
          inputs.mi2mqtt.overlay
        ];
      };

      # Router
      routenix = {
        nixos = inputs.nixos-2311;
        system = "x86_64-linux";
        overlays = [ inputs.nix-velocloud.overlay ];
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
