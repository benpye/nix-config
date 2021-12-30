{ config, pkgs, lib, ... }:

let
  hostName = "nixserve";
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;
  nix.trustedUsers = [ "ben" ];

  boot = {
    supportedFilesystems = [ "zfs" ];

    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/disk/by-id/usb-HP_iLO_Internal_SD-CARD_000002660A01-0:0";
    };

    initrd = {
      kernelModules = [ "tg3" ];

      network = {
        enable = true;

        ssh = {
          enable = true;
          # Different port for boot SSH to avoid mismatched certs
          port = 2222;
          authorizedKeys =
            [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDU7W3aX/Crbp4bKNRNZWRYaxgpH6tsjt88l6jspdlHToMz6Vvq4NU7CHwXNBijO0LTh7wxeKT3E5DZkPepE9gv7vRIrSX5NLHlLLAibC6iogF70SGqLeyEUXh70tMa+ZxU6wow5VcGxZ0RBXsuunKFhGqatveRaw6CbIYceLvnJvUBcsw0M3tr6EtyuTQ2p8BFoZNnYX+4Aj3HAz/uuwjUcgz3ri+Ot+yJKjkS2dV/aKCznQhvS3sX8Fio3eBI7XBm8oc5O1jI37y4Tckq/mnQORiTaKTvkbZmRojPgk7EdjACJJPVfk2mCnl/zcShQDyzOz5BhUOCvOObeJWseBp3"
            ];
          hostKeys =
            [
              /etc/secrets/initrd/ssh_host_rsa_key
              /etc/secrets/initrd/ssh_host_ed25519_key
            ];
        };
      };
    };
  };

  networking = {
    hostName = hostName;
    hostId = "8ea92bbd";
  };

  networking.useDHCP = false;
  networking.interfaces.eno2.useDHCP = true;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 139 443 445 631 ];
  networking.firewall.allowedUDPPorts = [ 80 137 138 443 631 ];

  # Use UTC for servers.
  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  # Use agent forwarding for sudo.
  security.pam.enableSSHAgentAuth = true;
  security.sudo.enable = true;

  security.acme = {
    email = "ben@curlybracket.co.uk";
    acceptTerms = true;
    certs = {
      "benpye.uk" = {
        extraDomainNames = [ "*.benpye.uk" ];
        dnsProvider = "cloudflare";
        credentialsFile = "/etc/secrets/acme.secret";
        group = "nginx";
      };
    };
  };

  services.nginx = {
    enable = true;

    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    recommendedProxySettings = true;

    virtualHosts =
    let
      extraConfig = ''
        add_header 'Strict-Transport-Security' 'max-age=63072000; includeSubDomains; preload';
      '';
    in {
      "bw.benpye.uk" = {
        useACMEHost = "benpye.uk";
        forceSSL = true;

        locations = {
          "/" = {
            inherit extraConfig;
            proxyPass = "http://localhost:8000";
          };

          "/notifications/hub" = {
            inherit extraConfig;
            proxyPass = "http://localhost:3012";
            proxyWebsockets = true;
          };

          "/notifications/hub/negotiate" = {
            inherit extraConfig;
            proxyPass = "http://localhost:8000";
          };
        };
      };

      "lounge.benpye.uk" = {
        useACMEHost = "benpye.uk";
        forceSSL = true;

        locations = {
          "/" = {
            inherit extraConfig;
            proxyPass = "http://localhost:9000";
            proxyWebsockets = true;
          };
        };
      };

      "miniflux.benpye.uk" = {
        useACMEHost = "benpye.uk";
        forceSSL = true;

        locations = {
          "/" = {
            inherit extraConfig;
            proxyPass = "http://localhost:9090";
          };
        };
      };
    };
  };

  services.avahi = {
    enable = true;
    cacheEntriesMax = 0;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  services.printing = {
    enable = true;
    browsing = true;
    defaultShared = true;
    drivers = [ pkgs.brlaser ];
    listenAddresses = [ "*:631" ];
    extraConf = pkgs.lib.mkForce ''
      <Location />
        Order allow,deny
        Allow from all
      </Location>
    '';
  };

  hardware.printers.ensurePrinters = [{
    description = "Brother HL-L2320D";
    name = "Brother_HL-L2320D";
    deviceUri = "usb://Brother/HL-L2320D%20series?serial=U63877F0N258909";
    model = "drv:///brlaser.drv/brl2320d.ppd";
    ppdOptions = {
      PageSize = "Letter";
      Duplex = "DuplexNoTumble";
    };
  }];

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "bitwarden_rs" "miniflux2" ];
    ensureUsers = [
      {
        name = "vaultwarden";
        ensurePermissions = {
          "DATABASE bitwarden_rs" = "ALL PRIVILEGES";
        };
      }
      {
        name = "miniflux2";
        ensurePermissions = {
          "DATABASE miniflux2" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      databaseUrl = "postgresql:///bitwarden_rs?host=/run/postgresql";
      domain = "https://bw.benpye.uk";
      signupsAllowed = false;
      websocketEnabled = true;
    };
  };

  services.ssmtp = {
    enable = true;

    authUser = "ben@curlybracket.co.uk";
    authPassFile = "/etc/secrets/fastmail.secret";

    useTLS = true;
    hostName = "smtp.fastmail.com:465";
    domain = "curlybracket.co.uk";
    root = "root@curlybracket.co.uk";
  };

  services.smartd = {
    enable = true;

    devices = [
      { device = "/dev/disk/by-id/ata-Crucial_CT120M500SSD1_13390951485C"; }
      { device = "/dev/disk/by-id/ata-HDS723030ALA640_RSD_HUA_MK0331YHGV1BUA"; }
      { device = "/dev/disk/by-id/ata-HDS723030ALA640_RSD_HUA_MK0361YHGMZTTD"; }
      { device = "/dev/disk/by-id/ata-HDS723030ALA640_RSD_HUA_MK0361YHGNPEVD"; }
      { device = "/dev/disk/by-id/ata-HDS723030ALA640_RSD_HUA_MK0361YHGNW0PD"; }
    ];

    notifications = {
      mail = {
        enable = true;
        sender = "smartd@curlybracket.co.uk";
        recipient = "ben@curlybracket.co.uk";
      };
    };
  };

  services.zfs.autoScrub = {
    enable = true;
    interval = "Sun, 02:00";
  };

  services.zfs.autoSnapshot = {
    enable = true;
    flags = "-k -p --utc";
  };

  services.thelounge = {
    enable = true;
    private = true;
    extraConfig = {
      reverseProxy = true;
    };
  };

  services.samba = {
    enable = true;

    extraConfig = ''
      inherit permissions = yes

      map archive = no
      map hidden = no

      vfs objects = shadow_copy2
      shadow: snapdir = .zfs/snapshot
      shadow: sort = desc
      shadow: format = -%Y-%m-%d-%H%M
      shadow: snapdirseverywhere = yes
      shadow: snapprefix = ^zfs-auto-snap_\(frequent\)\{0,1\}\(hourly\)\{0,1\}\(daily\)\{0,1\}\(monthly\)\{0,1\}
      shadow: delimiter = -20
    '';

    shares = {
      library = {
        path = "/tank/library";
        browseable = "yes";
        "read only" = "yes";
        "write list" = "@sharewriters";
        "force group" = "nogroup";
      };
    };
  };

  services.miniflux = {
    enable = true;
    package = pkgs.unstable.miniflux;
    config = {
      RUN_MIGRATIONS = "1";
      CREATE_ADMIN = "1";
      BASE_URL = "https://miniflux.benpye.uk";
      ADMIN_USERNAME_FILE = "/etc/secrets/miniflux/admin_user.secret";
      ADMIN_PASSWORD_FILE = "/etc/secrets/miniflux/admin_pass.secret";
      DATABASE_URL = "postgresql:///miniflux2?host=/run/postgresql";
      LISTEN_ADDR = "127.0.0.1:9090";
    };
  };

  services.restic.backups = {
    media = {
      paths = [
        "/tank/library/lightroom"
        "/tank/library/photos"
      ];
      repository = "b2:benpye-backup:nixserve/media";
      initialize = true;
      passwordFile = "/etc/secrets/restic/media/repo";
      environmentFile = "/etc/secrets/restic/media/b2_credentials";
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
      ];
    };
  };

  users.users = {
    ben = {
      extraGroups = [ "wheel" "sharewriters" ];
      uid = 1000;
      isNormalUser = true;
      openssh.authorizedKeys.keys =
        [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDU7W3aX/Crbp4bKNRNZWRYaxgpH6tsjt88l6jspdlHToMz6Vvq4NU7CHwXNBijO0LTh7wxeKT3E5DZkPepE9gv7vRIrSX5NLHlLLAibC6iogF70SGqLeyEUXh70tMa+ZxU6wow5VcGxZ0RBXsuunKFhGqatveRaw6CbIYceLvnJvUBcsw0M3tr6EtyuTQ2p8BFoZNnYX+4Aj3HAz/uuwjUcgz3ri+Ot+yJKjkS2dV/aKCznQhvS3sX8Fio3eBI7XBm8oc5O1jI37y4Tckq/mnQORiTaKTvkbZmRojPgk7EdjACJJPVfk2mCnl/zcShQDyzOz5BhUOCvOObeJWseBp3"
        ];
    };
  };

  environment.systemPackages = [ ];

  users.groups = {
    share = {
      gid = 1000;
    };

    sharewriters = {
      gid = 1001;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
