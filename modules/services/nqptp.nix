{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nqptp;
in {
  options = {
    services.nqptp = {
      enable = mkEnableOption "nqptp";

      port = mkOption {
        default = 50000;
        type = types.port;
        description = ''
          On which port to listen.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.nqptp = {
      description = "nqptp";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "network.target" "network-online.target" ];
      before      = [ "shairport-sync.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.nqptp}/bin/nqptp";
        User = "root";
        Group = "root";
      };
    };
  };
}
