{
  description = "Nix configuration flake.";

  inputs = {
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    launchd_shim = {
      url = "github:benpye/launchd_shim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, home-manager, launchd_shim, ... }: {
    homeConfigurations = {
      m1pro = home-manager.lib.homeManagerConfiguration {
        configuration = {
          nixpkgs.overlays = [ launchd_shim.overlay ];
          imports = [
            ./modules/launchd/default.nix
            ./modules/disable-systemd.nix

            ./modules/services/dirmngr.nix
            ./modules/services/gpg-agent.nix

            ./machine/m1pro.nix
          ];
        };
        system = "x86_64-darwin";
        homeDirectory = "/Users/benpye";
        username = "benpye";
      };
    };
  };
}
