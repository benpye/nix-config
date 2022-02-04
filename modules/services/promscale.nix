{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.promscale;
in {
  options = {
    services.promscale = {
      enable = mkEnableOption "promscale";

      config = mkOption {
        default = null;
        type = types.nullOr types.attrs;
        description = ''
          promscale configuration as nix attribute set.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.promscale = {
      description = "promscale";
      wantedBy = [ "multi-user.target" ];
      requires = [ "postgresql.service" ];
      after = [ "network.target" "postgresql.service" ];

      serviceConfig = let
        configFile = pkgs.writeText "config.yaml" (builtins.toJSON cfg.config);
      in {
        User = "promscale";
        Group = "promscale";
        ExecStart = "${pkgs.promscale}/bin/promscale -config ${configFile}";
        PrivateTmp = "true";
        PrivateDevices = "true";
        PrivateHome = "true";
        ProtectHome = "true";
        ProtectSystem = "strict";
        AmbientCapabilities = "cap_net_bind_service";
      };
    };

    users.users.promscale = {
      isSystemUser = true;
      group = "promscale";
    };

    users.groups.promscale = {};
  };
}
