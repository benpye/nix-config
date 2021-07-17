{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.matrix-ircd;
in {
  options = {
    services.matrix-ircd = {
      enable = mkEnableOption "duckling";

      address = mkOption {
        type = types.str;
        default = "127.0.0.1:5999";
        description = ''
          Address on which matrix-ircd will listen.
        '';
      };

      server = mkOption {
          type = types.str;
          default = "https://matrix.org";
          description = ''
           The base url of the Matrix HS.
          '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.matrix-ircd = {
      description = "matrix-ircd daemon";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.matrix-ircd}/bin/matrix-ircd --bind ${cfg.address} --url ${cfg.server}";
        Restart = "always";
        DynamicUser = true;
      };
    };
  };
}
