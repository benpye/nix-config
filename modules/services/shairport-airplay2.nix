{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.shairport-airplay2;

  # Basically a tinkered lib.generators.mkKeyValueDefault
  # It either serializes an expression "key = { values };"
  mkAttrsString = mapAttrsToList (k: v:
      "${escape [ "=" ] k} = ${mkValueString v};");

  # This serializes a Nix expression to the libconfig format.
  mkValueString = v:
         if types.bool.check  v then boolToString v
    else if types.int.check   v then toString v
    else if types.float.check v then toString v
    else if types.str.check   v then "\"${escape [ "\"" ] v}\""
    else if builtins.isList   v then "[ ${concatMapStringsSep " , " mkValueString v} ]"
    else if types.attrs.check v then "{ ${concatStringsSep " " (mkAttrsString v) } }"
    else throw ''
                 invalid expression used in option services.shairport-airplay2.config:
                 ${v}
               '';

  toConf = attrs: concatStringsSep "\n" (mkAttrsString attrs);

  configFile = pkgs.writeText "shairport-sync.conf" (toConf cfg.config);

in

{

  ###### interface

  options = {

    services.shairport-airplay2 = {

      enable = mkOption {
        type = types.bool;
        default = false;
      };

      arguments = mkOption {
        type = types.str;
        default = "-v";
      };

      config = mkOption {
        default = null;
        type = types.nullOr types.attrs;
        description = ''
          shairport-sync configuration as nix attribute set.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
      };

      user = mkOption {
        type = types.str;
        default = "shairport";
        description = lib.mdDoc ''
          User account name under which to run shairport-sync. The account
          will be created.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "shairport";
        description = lib.mdDoc ''
          Group account name under which to run shairport-sync. The account
          will be created.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf config.services.shairport-airplay2.enable {

    services.avahi.enable = true;
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;

    users = {
      users.${cfg.user} = {
        description = "Shairport user";
        isSystemUser = true;
        createHome = true;
        home = "/var/lib/shairport-sync";
        group = cfg.group;
        extraGroups = [ "audio" ] ++ optional config.hardware.pulseaudio.enable "pulse";
      };
      groups.${cfg.group} = {};
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 5000 7000 ];
      allowedTCPPortRanges = [ { from = 32768; to = 60999; } ];
      allowedUDPPortRanges = [ { from = 6000; to = 6009; } { from = 32768; to = 60999; } ];
    };

    systemd.services.shairport-sync =
      {
        description = "shairport-sync";
        after = [ "network.target" "avahi-daemon.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${pkgs.shairport-airplay2}/bin/shairport-sync -c ${configFile} ${cfg.arguments}";
          RuntimeDirectory = "shairport-sync";
        };
      };

    environment.systemPackages = [ pkgs.shairport-airplay2 ];

  };

}
