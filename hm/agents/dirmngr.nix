{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.dirmngr;

in

{
  options = {
    services.dirmngr = {
      enable = mkEnableOption "GnuPG network certificate management daemon";

      verbose = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to produce verbose output.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    launchd.user.agents.dirmngr = {
      serviceConfig = {
        Umask = "0600";
        ProgramArguments = [
          "${pkgs.gnupg}/bin/dirmngr"
          "--supervised"
          (mkIf cfg.verbose "--verbose")
        ];

        Sockets = {
          std = {
            SockPathName = "${config.home.homeDirectory}/.gnupg/S.dirmngr";
            SockPathMode = "0600";
          };
        };
      };

      systemdSocketActivation = true;
    };
  };
}
