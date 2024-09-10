{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mi2mqtt;
in {
  options = {
    services.mi2mqtt = {
      enable = mkEnableOption "mi2mqtt";

      server = mkOption {
        default = "mqtt://localhost:1883?client_id=mi2mqtt";
        type = types.str;
        description = ''
          MQTT server to publish to.
        '';
      };

      topic = mkOption {
        default = "mi_sensor";
        type = types.str;
        description = ''
          MQTT topic to publish to.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.mi2mqtt = {
      description = "mi2mqtt";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "network.target" ];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.mi2mqtt}/bin/mi2mqtt \
          --mqtt-url ${cfg.server} \
          --topic ${cfg.topic}
          '';
        Restart = "always";
        DynamicUser = true;
      };
    };
  };
}
