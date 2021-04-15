{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gpg-agent;

in

{
  options = {
    services.gpg-agent = {
      enableBrowserSocket = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable browser socket of the GnuPG key agent.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      launchd.user.agents.gpg-agent = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.gnupg}/bin/gpg-agent"
            "--supervised"
            (mkIf cfg.verbose "--verbose")
          ];

          Sockets = mkMerge [
            {
              std = {
                SockPathName = "${config.home.homeDirectory}/.gnupg/S.gpg-agent";
                SockPathMode = "0600";
              };
            }

            (mkIf cfg.enableSshSupport {
              ssh = {
                SockPathName = "${config.home.homeDirectory}/.gnupg/S.gpg-agent.ssh";
                SockPathMode = "0600";
              };
            })

            (mkIf cfg.enableExtraSocket {
              extra = {
                SockPathName = "${config.home.homeDirectory}/.gnupg/S.gpg-agent.extra";
                SockPathMode = "0600";
              };
            })

            (mkIf cfg.enableBrowserSocket {
              browser = {
                SockPathName = "${config.home.homeDirectory}/.gnupg/S.gpg-agent.browser";
                SockPathMode = "0600";
              };
            })
          ];
        };

        systemdSocketActivation = true;
      };
    }

    (mkIf cfg.enableSshSupport {
      launchd.user.agents.gpg-agent-symlink = {
        serviceConfig = {
          ProgramArguments = [
            "/bin/sh"
            "-c"
            "/bin/ln -sf ${config.home.homeDirectory}/.gnupg/S.gpg-agent.ssh $SSH_AUTH_SOCK"
          ];
          RunAtLoad = true;
        };
      };
    })
  ]);
}
