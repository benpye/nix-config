{
  description = "Nix configuration flake.";

  inputs = {
    # Unstable channels
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable release channels
    nixpkgs-2009.url = "github:nixos/nixpkgs/release-20.09";
    nixos-2009.url = "github:nixos/nixpkgs/nixos-20.09";

    # Darwin aarch64 channel
    nixpkgs-darwin-aarch64.url = "github:thefloweringash/nixpkgs/apple-silicon";

    home-manager-darwin-aarch64 = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin-aarch64";
    };

    launchd_shim = {
      url = "github:benpye/launchd_shim";
      inputs.nixpkgs.follows = "nixpkgs-darwin-aarch64";
    };

    # deploy-rs on unstable
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # deploy-rs for stable targets
    deploy-rs-2009 = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixos-2009";
    };
  };

  outputs = inputs@{ self, ... }:
  let
    lib = import ./lib {};
  in
  {
    # deploy-rs with unstable nixpkgs available locally
    apps = builtins.mapAttrs (_: deploy: { inherit deploy; }) inputs.deploy-rs.defaultApp;

    homeConfigurations = lib.mkHomeConfigurations {
      m1pro = {
        home-manager = inputs.home-manager-darwin-aarch64;
        system = "aarch64-darwin";
        username = "benpye";
        homeDirectory = "/Users/benpye";
        overlays = [ inputs.launchd_shim.overlay ];
      };
    };

    nixosConfigurations = lib.mkNixosConfigurations {
      nixserve = {
        nixos = inputs.nixos-2009;
        system = "x86_64-linux";
        overlays = [
          (self: super: { unstable = inputs.nixpkgs.legacyPackages.x86_64-linux; })
        ];
      };
    };

    deploy = {
      nodes = {
        nixserve = {
          hostname = "nixserve";
          profiles.system = {
            user = "root";
            sshUser = "ben";
            sshOpts = [ "-A" ];
            path = inputs.deploy-rs-2009.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixserve;
          };
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs-2009.lib;
  };
}
