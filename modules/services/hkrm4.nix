{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.hkrm4;
in
{
  options = {
    services.hkrm4 = {
      enable = mkEnableOption "hkrm4";

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

      config = mkOption {
        default = null;
        type = types.nullOr types.attrs;
        description = ''
          hkrm4 configuration as nix attribute set.
        '';
      };

      metricsPort = mkOption {
        default = null;
        type = types.nullOr types.port;
        description = ''
          On which port to expose the metrics endpoint.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.hkrm4 = {
      description = "hkrm4";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig =
        let
          configFile = pkgs.writeText "config.json" (builtins.toJSON cfg.config);
        in
        {
          ExecStart = ''
            ${pkgs.hkrm4}/bin/hkrm4 \
            -port ${toString cfg.port} \
            -data /var/lib/hkrm4 \
            -config ${configFile} \
            -pin ${cfg.pin} \
            ${optionalString (cfg.metricsPort != null) "-metrics ${toString cfg.metricsPort}"}
          '';
          Restart = "always";
          DynamicUser = true;
          StateDirectory = "hkrm4";
        };
    };
  };
}
