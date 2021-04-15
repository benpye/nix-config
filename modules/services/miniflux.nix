{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.miniflux;
in {
  disabledModules = [ "services/web-apps/miniflux.nix" ];

  options = {
    services.miniflux = {
      enable = mkEnableOption "miniflux";

      config = mkOption {
        type = types.attrsOf types.str;
        example = literalExample ''
          {
            CLEANUP_FREQUENCY = "48";
            LISTEN_ADDR = "localhost:8080";
          }
        '';
        description = ''
          Configuration for Miniflux, refer to
          <link xlink:href="https://miniflux.app/docs/configuration.html"/>
          for documentation on the supported values.
        '';
      };

      package = mkOption {
        default = pkgs.miniflux;
        defaultText = "pkgs.miniflux";
        example = "pkgs.miniflux";
        type = types.package;
        description = ''
          Miniflux package to use.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    systemd.services.miniflux = {
      description = "Miniflux service";
      wantedBy = [ "multi-user.target" ];
      requires = [ "postgresql.service" ];
      after = [ "network.target" "postgresql.service" ];

      serviceConfig = {
        User = "miniflux2";
        Group = "miniflux2";
        ExecStart = "${cfg.package}/bin/miniflux";
        PrivateTmp = "true";
        PrivateDevices = "true";
        PrivateHome = "true";
        ProtectHome = "true";
        ProtectSystem = "strict";
        AmbientCapabilities = "cap_net_bind_service";
      };

      environment = cfg.config;
    };

    users.users.miniflux2 = {
      isSystemUser = true;
      group = "miniflux2";
    };

    users.groups.miniflux2 = {};

  };
}
