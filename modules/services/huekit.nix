{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.huekit;
in
{
  options = {
    services.huekit = {
      enable = mkEnableOption "huekit";

      port = mkOption {
        default = 50000;
        type = types.port;
        description = ''
          On which port to listen.
        '';
      };

      pin = mkOption {
        default = "00102003";
        type = types.str;
        description = ''
          PIN to use for HomeKit pairing.
        '';
      };

      bridgeAddress = mkOption {
        type = types.str;
        description = ''
          IP address of Hue bridge.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.huekit = {
      description = "huekit";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.huekit}/bin/huekit";
        Environment = [
          "HUEKIT_LOG_LEVLE=info"
          "HUEKIT_LOG_FORMAT=text"
          "HUEKIT_BRIDGE_ADDRESS=${cfg.bridgeAddress}"
          "HUEKIT_HOMEKIT_PIN=${cfg.pin}"
          "HUEKIT_HOMEKIT_PORT=${toString cfg.port}"
        ];
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "huekit";
        WorkingDirectory = "/var/lib/huekit";
      };
    };
  };
}
