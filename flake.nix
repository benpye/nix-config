{
  description = "Nix configuration flake.";

  inputs = {
    nixos-2009 = {
      url = "github:nixos/nixpkgs/nixos-20.09";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    nixpkgs-darwin-aarch64 = {
      url = "github:thefloweringash/nixpkgs/apple-silicon";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin-aarch64";
    };

    launchd_shim = {
      url = "github:benpye/launchd_shim";
      inputs.nixpkgs.follows = "nixpkgs-darwin-aarch64";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    deploy-rs-2009 = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixos-2009";
    };
  };

  outputs = { self, home-manager, launchd_shim, nixos-2009, nixpkgs-unstable, deploy-rs, deploy-rs-2009, ... }: {
    # note that this is the only place we use `deploy-rs`, built with unstable nixpkgs:
    apps = builtins.mapAttrs (_: deploy: { inherit deploy; }) deploy-rs.defaultApp;

    homeConfigurations = {
      m1pro = home-manager.lib.homeManagerConfiguration {
        configuration = {
          nixpkgs.overlays = [
            launchd_shim.overlay
            (import ./overlays/qemuPatched)
          ];
          imports = [
            ./modules/launchd
            ./modules/disable-systemd.nix

            ./modules/services/dirmngr.nix
            ./modules/services/gpg-agent.nix

            ./machine/m1pro
          ];
        };
        system = "aarch64-darwin";
        homeDirectory = "/Users/benpye";
        username = "benpye";
      };
    };

    nixosConfigurations = {
      nixserve = nixos-2009.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ ... }:
          {
            nixpkgs.overlays = [
              (import ./overlays/brlaserPatched)
              (import ./overlays/unifi61)
            ];
          })
          nixos-2009.nixosModules.notDetected
          ./machine/nixserve
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
            path = deploy-rs-2009.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixserve;
          };
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs-2009.lib;
  };
}
