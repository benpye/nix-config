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
      device = "/dev/disk/by-id/usb-Kingston_DataTraveler_3.0_002618086C69F051F849AA30-0:0";
    };

    initrd = {
      kernelModules = [ "tg3" "mlx4_core" "mlx4_en" ];

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
    inherit hostName;
    hostId = "8ea92bbd";
  };

  networking.useDHCP = false;
  networking.interfaces.eno2.useDHCP = true;
  networking.interfaces.enp7s0.useDHCP = true;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 139 443 445 631 5353 9003 50000 50002 50004 ];
  networking.firewall.allowedUDPPorts = [ 80 137 138 443 631 5353 ];

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
    acceptTerms = true;
    defaults.email = "ben@curlybracket.co.uk";
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

  services.avahi = {
    enable = true;
    cacheEntriesMax = 0;
    publish = {
      enable = true;
      userServices = true;
    };
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
    package = pkgs.postgresql_14;
    dataDir = "/persist/pgsql/14";
    ensureDatabases = [ "bitwarden_rs" ];
    ensureUsers = [
      {
        name = "vaultwarden";
        ensurePermissions = {
          "DATABASE bitwarden_rs" = "ALL PRIVILEGES";
        };
      }
    ];
    settings = {
      full_page_writes = false;
    };
  };

  systemd.services.postgresql.serviceConfig.TimeoutStartSec = "infinity";

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

  programs.msmtp = {
    enable = true;

    accounts.default = {
      tls = true;
      auth = true;
      host = "smtp.fastmail.com";
      port = 465;
      user = "ben@curlybracket.co.uk";
      passwordeval = "cat /etc/secrets/fastmail.secret";
    };
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
    interval = "Mon, 09:00";
  };

  services.zfs.autoSnapshot = {
    enable = true;
    flags = "-k -p --utc";
  };

  services.thelounge = {
    enable = true;
    public = false;
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

  services.hkrm4 = {
    enable = false;
    metricsPort = 50001;
    config = {
      ip = "192.168.10.78";
      mac = "ec:0b:ae:23:f2:78";
      type = 25755;
      fans = [
        {
          id = "office-ceiling";
          name = "Ceiling Fan";
          manufacturer = "Hunter Fan Company";
          model = "59244";
          firmwareRevision = "N/A";
          serialNumber = "N/A";

          commands = {
            lightToggle = "scB8As6eBgAMDQ0NDQ0ODQ0NDQ0NDQ0NDQ4NDQ0NDaobDQ0aGg0aDhoNDRsMGwwbGg4MGxkOGg4ZDhkPCxwMGxkODRoaDgwbGg4ZDgwbGg0NGxkOGg0aDgwbDRoNGxoNDRoaDhkOGQ4aDRoOGQ4aDQ0bDBsNGg0bGg0NGg0bDBsNGg0bDBsNGg0bGQ4aDRoODBsaDRoNGg4aDRoOGQ4ZDhoODAADSQ0NDg0NDQ0NDQ0NDQ0ODQ0NDQ0NDQ0OqhoNDRobDRoOGQ4MGw0aDRsaDQ0aGg4ZDhoNGg4MGwwbGg4MGxoNDRsZDhoNDRsZDgwbGg0aDhkODRoNGw0aGg0NGxkOGg0aDhoNGg0aDhkODRoNGwwbDRoaDgwbDRoNGg0bDRoNGg0bDBsaDRoOGg0NGhoOGQ4aDRoOGQ4aDhkOGQ4MAAOnDgwODA4NDQ0NDQ0ODQ0NDQ0NDQ0NDg2qGg0OGhoNGg0aDg0aDRoNGxoNDRoaDhoNGg4ZDgwbDRsZDgwbGg4MGxoNGg4MGxkODBsaDhkOGg0NGwwbDBsaDgwbGg0aDhkOGg0aDhkOGQ4NGwwbDBsNGwwbDBsNGhoODBsMGxoOGQ4NGhoOGQ4aDRoOGQ4ZDg0bGQ4ZDg0bDBsZDg0AA0gODQ4MDgwODQ0NDQ0NDQ0NDg0NDQ0NDasaDQ0aGg4aDRoNDRsMGw0aGg4NGhoNGg4ZDhoODBsMGxoNDRsZDgwbGg4ZDgwbGg4MGxoNGg4ZDgwbDRsMGxkODRsZDhkOGg0aDhkOGg0aDgwbDRoNGwwbDBsNGwwbGQ4NGwwbGg0aDQ0bGQ4aDRoOGQ4aDRoODBsaDRoODBsNGhoODAAF3A==";
            speed = [
              "scB8As6eBgANDA4NDQ0ODA4MDg0NDQ0NDgwODQ0NDasaDQ0aGg4ZDhoNDRsMGwwbGg0NGxkOGg0aDhkODRoNGxkODRoaDgwbGg0aDgwbGg0NGxkOGg0aDgwbDBsNGhoODBsaDRoOGg0aDRoOGQ4aDQ0bDBsNGg0bDBsNGg0aDRsNGg0aDRsNGhoNGg4aDRoOGQ4ZDhoOGQ4ZDhoOGQ4ZDg0bDAADSQ4MDgwODA4NDQ0NDQ0NDg0NDQ0NDQ0NqxoNDRobDRoNGg4MGw0aDRsaDQ0aGg0aDhoNGg4MGw0aGg4MGxoNDRoaDhoNDRoaDgwbGg0aDhkODRoNGwwbGg0NGxkOGg0aDhkOGg0aDhkODBsNGg0bDBsNGg0bDBsNGg0bDBsNGg0bGQ4aDRoOGQ4aDRoOGQ4aDRoOGQ4aDRoODBsMAAOFDQ0ODA4MDgwODQ0NDgwODQ0NDQ0NDQ2qGw0NGhsNGg0aDgwbDRoNGhoODRoaDRoOGQ4aDQ0bDBsaDQ0bGQ4NGhoOGQ4NGhoODBsaDRoNGg4MGw0aDRsaDQ0aGg4aDRoNGg4ZDhoNGg4MGw0aDRsMGw0aDRoNGxoNDRoNGw0aGg4MGxoNGg0aDhoNGg0aDgwbGg4ZDhkODRoaDgwAA0kODA4NDQ0ODA4MDgwODQ0NDQ0NDg0NDaoaDQ4aGg0aDhoNDRoNGwwbGg0NGxkOGg0aDhkODBsNGxkODBsaDQ0bGg0aDQ0bGg0NGhoOGg0aDQ0bDBsNGhoODBsaDRoOGQ4aDRoOGQ4ZDg0bDBsMGw0aDRsMGw0aGg4MGw0aDRsZDg0aGg0aDhoNGg4ZDhoNDRsZDhoNGg4MGxoNDQAF3A=="
              "scBCAc6eBgAPBAQHDgwODA4MDg0NDQ0NDQ0ODQ0NDQ0NqxoNDRoaDhoNGg4MGwwbDRoaDgwbGg0aDhkOGg0NGwwbGg0NGxkODRoaDhkODBsaDgwbGQ4aDhkODBsNGg0bGQ4NGhoOGQ4aDRoOGQ4ZDhoODBsNGg0bDBsNGg0aDRsNGg0aDRsNGhoNDRsaDRoNGg4aDRoNGg4ZDhoNGg4ZDgwbGg4MAANJDgwODQ0NDQ0ODA4MDg0NDQ0NDQ0NDg2qGg0OGhoNGg0bDQ0aDRsMGxoNDRoaDhkOGg4ZDgwbDRsZDgwbGg0NGxkOGg0NGxkODRoaDhkOGg0NGwwbDRoaDgwbGQ4aDhkOGQ4aDhkOGQ4NGg0bDBsNGg0bDBsNGg0bDBsNGg0bGg0NGhoNGg4aDRoOGQ4aDRoOGQ4ZDhoODBsaDQ0ABdw="
              "scA6Ac6eBgBtCQ4MDg0NDQ0NDgwODQ0NDaobDQ0aGg4ZDhkODRsMGwwbGg4MGxkOGg0aDhkODRoNGxkODRoaDgwbGg0aDgwbGg0NGxkOGg0aDgwbDBsNGhoODRoaDRoOGQ4aDRoOGQ4aDgwbDBsNGg0bDBsNGg0bGg0NGg0bDBsNGg0aGg4aDRoNGg4aDRoODBsaDRoOGQ4ZDhoODAADSQ0NDgwODQ0NDQ0NDQ0ODQ0NDQ0NDgwOqhoNDRobDRoNGg4MGw0aDRsaDQ0aGg4aDRoNGg4MGw0aGg4MGxoNDRoaDhoNDRoaDgwbGg0aDhkODRoNGwwbGg0NGxoNGg0aDhkOGg0aDhkODBsNGg0bDBsNGg0bDBsaDQ0bDRoNGg0bDBsaDRoOGQ4aDRoOGQ4MGxoOGQ4aDRoOGQ4MAAXc"
              "scBAAc6eBgAMDQ0NDQ0NDQ4NDQ0NDQ0NDQ0NDg0NDaoaDg0aGg0aDhkODRoNGwwbGg0NGxkOGg4ZDhkODBwMGxkODBsaDgwbGg0aDgwbGg0NGxkOGg0aDgwbDBsNGhoODBsaDRoOGQ4aDRoOGQ4aDQ0bDBsNGg0bDBsNGhoNDRsNGg0aDRsNGg0bGQ4aDRoNGg4aDQ0aGg4aDRoNGg4ZDhkPDAADSQ0NDgwODA4NDQ0NDQ4MDg0NDQ0NDQ0NqxoNDRobDRoNGg4NGg0aDRoaDgwbGg4ZDhoNGg4MGwwbGg4MGxkODBwZDhkODRsZDgwbGg0aDhkODBsNGwwbGg0NGxkOGg0aDhkOGQ4aDhkODBsNGg0bDBsNGg0bGg0NGg0bDBsNGg0bDBsaDRoOGQ4aDRoODBsaDRoOGQ4aDRoNGg4MAAXc"
            ];
          };
        }
        {
          id = "bedroom-ceiling";
          name = "Ceiling Fan";
          manufacturer = "Hunter Fan Company";
          model = "59244";
          firmwareRevision = "N/A";
          serialNumber = "N/A";

          commands = {
            lightToggle = "ssBsAlCfBgD3BA4MDgwOqhoNDRsNGhoOGQ4NGhoOGQ4ZDg0bDBsMGxoODBsMGxoNDRsMGxoNDRsMGw0aDRoaDhoNGg0NGxoNGg0aDhoNGg0NGxoNGg0NGxoNDRoaDhoNGg0NGwwbDRoaDgwbDRoNGwwbDRoNGwwbDRoaDRoOGg0NGxkOGg0aDRoOGQ4aDRoOGQ4NAANIDg0NDQ0NDQ4NDQ0NDQ0NDQ4NDQ0NDQ2qGw0NGg0aGw0aDQ0aGw0aDRoODBsNGg0aGg4MGw0aGg4MGw0aGg4MGw0aDRsNGhoNGg4aDQ0aGg0aDhoNGg4ZDgwbGg0aDg0aGg4MGxoNGg0aDgwbDRoNGxkODRoNGw0aDRoNGwwbDRoNGxkOGg0aDgwbGg0bDRkOGQ4aDhkOGQ4aDgwAA6cNDQ0NDQ0ODQ0NDQ0NDQ4NDQ0NDQ0NDasaDQ0aDhoaDRoNDRsaDRoNGg4NGg0aDRsaDQ0aDRsaDQ0aDRsaDQ0aDRsMGw0aGg0bDRoNDRobDRoNGg4ZDhoNDRsZDhoNDRoaDgwbGg0aDhoNDRoNGwwbDRoNGwwbGg0NGwwbGg0aDQ0bGg0aDRsNGg0aDhkODBsaDRoODBsNGhoODQADSA4MDg0NDQ0NDgwODQ0NDQ0NDQ0ODQ0NqhoNDhoNGhsMGw0NGhoNGw0aDQ0bDBsNGhoNDRsNGhoNDRsNGhoNDRsNGg0aDRsaDRoNGg4NGhoNGg4aDRoNGg4MGxoNGg4MGxoNDRsZDhoNGg0NGw0aDRoNGw0aDRoaDgwbDRoaDhoNDRoaDhoNGg0aDhkOGg4MGxkOGg0NGwwbGg0NAAXc";
            speed = [
              "ssDkAlCfBgAGBQQhDCMIEQ4LBgQECwQEBBIFEScLEAQEGxYbDAQEHBgaBxIGEQcRBhoEFgQMDwkOCgQUBwYEDAQGBAsFEg8JBhIPCQ0PBBYEEgYSBxEPCQ8KDAwFBAQkBxAHEgcRBxIFEgcRDgsGKQ8JBxEGEgYSBgmpBA8LDwwODA4NDQ0NqhsNDRoNGhoOGg0NGhoOGg0aDQ0bDBsNGhoODBsNGhoODBsNGhoNDRsNGg0aDRsaDRoNGg4MGxoNGg4aDRoNGg4MGxoNGg4MGxoNDRoaDhoNGg4MGw0aDRsMGw0aDRoNGw0aDRoNGw0aGg0aDhoNGg0aDhkOGg4ZDhkOGg0aDhkODRoNAANJDgwODA4MDg0NDQ0NDgwODQ0NDQ0NDQ2rGg0NGg4aGg0aDQ0bGg0aDRoODBsNGg0bGg0NGg0bGg0NGg0bGg0NGg0bDRoNGhoNGw0aDQ0aGg4aDRoNGg4aDQ0aGg4aDQ0aGg4NGhoOGQ4aDQ0aDRsNGg0aDRsMGw0aDRoOGg0aDRsZDhoNGg4ZDhoNGg4ZDhoNGg4ZDhkOGg4MGw0AA4MODA4MDgwODQ4MDgwODA4MDg0NDQ0NDqoaDQ0aDhoaDRoNDhoaDRoNGw0NGg0bDRoaDQ0aDRsaDQ0aDRsaDQ0aDRsNGg0aGg4aDRoNDRsaDRoNGg4ZDhoNDRsZDhoNDRsZDg0aGg4ZDhoNDRoNGw0aDRoNGw0aGg0NGw0aDRoaDgwbGg0aDhoNGg0aDhkODRoaDhoNGg0NGhsNDQADSA4MDg0NDQ0NDgwODQ0NDQ0NDQ4NDQ0NqhsNDRoNGhsNGg0NGhoOGg0aDQ0bDRoNGhoODBsNGhoODRoNGhoODBsNGg0aDRsaDRoNGg4NGhoNGg4aDRoOGQ4NGhoOGQ4NGhoNDRsZDhoNGg4MGw0aDRsMGw0aDRsZDg0aDRsMGxoNDRsZDhoNGg0aDhoNGg0NGxoNGg0aDgwbGg0NAAXc"
              "ssAwAVCfBgDxCA4NDQ0NqxoNDRsMGxoNGg4MGxoOGQ4ZDg0bDBsMGxoNDRsMGxoNDRoNGxkODRoNGw0aDRoaDhoNGg0NGhsNGg0aDhkOGg0NGxkOGg0NGhoODRoaDRoOGg0NGg0bDRoNGg0bDBsNGg0bDBsNGhoODBsaDRoOGQ4aDRoOGQ4aDRoOGQ4aDQ0bGQ4NAANIDg0NDQ0NDQ0NDQ4NDQ0NDQ0NDg0NDQ2qGg4NGg0aGg4aDQ0aGg4aDRoNDRsMGw0aGg4MGw0aGg0NGw0aGg0NGw0aDRoOGhoNGg0aDg0aGg0aDhoNGg0aDgwbGg0aDgwbGg0NGhoOGg0aDgwbDRoNGg0bDRoNGg0bDRoNGg0bGg0NGhoOGQ4aDRoOGQ4aDRoOGQ4aDRoODBsaDQ0ABdw="
              "ssAwAVCfBgD2BA4MDg0NqhoODRoNGhoOGg0NGhoOGQ4aDgwbDBsNGhoODBsNGhoODBsNGhoNDRsNGg0aDRsaDRoNGg4MGxoNGg4aDRoNGg4NGhoNGg4MGxoNDRoaDhoNGg0NGw0aDRoOGg0aDRoaDg0aDRoNGw0aDRoaDhoNGg0aDRsNGg0NGhoOGg0aDhkOGg0NAANIDwwODA4MDgwODQ0NDgwODA4NDQ0NDQ2rGg0NGg4aGg0aDQ0bGg0aDRoODRoNGg0bGg0NGg0bGg0NGg0bGg0NGg0bDBsNGhoNGg4aDQ0aGg4aDRoNGg4aDQ0aGg4aDQ0aGg4MGxoNGg4ZDg0aDRsMGw0aDRoOGhoNDRoOGg0aDRoOGhoNGg0aDhoNGg0aDg0aGg0aDhoNGg0aDgwABdw="
              "ssAwAVCfBgAAAQcODgwOqhoNDRoNGxoNGg4MGxoNGg4ZDgwbDRsMGxkODRsMGxkODRoNGxkODRoNGwwbDRoaDhoNGg0NGxoNGg0aDhkOGg0NGxkOGg0NGxkODRoaDRoOGg0NGg0bDBsNGg0bGg0NGg0bDBsNGg0bDBsaDRoNGw0aDRoNDRsaDRoNGg4aDRoNGg4MAANJDgwODQ0NDQ0ODA4NDQ0NDQ0NDgwODQ2qGw0NGg0aGwwbDQ0aGwwbDRoNDRsMGw0aGg4MGw0aGg4MGw0aGg4MGw0aDRoNGxoNGg0aDg0aGg0aDhoNGg0aDgwbGg0aDgwbGg0NGxoNGg0aDgwbDRoNGg0bDRoaDQ0bDRoNGg0bDRoNGhoOGg0aDRoOGg0NGhoNGw0aDRoOGQ4aDQ0ABdw="
            ];
          };
        }
      ];
    };
  };

  services.huekit = {
    enable = false;
    port = 50002;
    bridgeAddress = "192.168.10.64";
  };

  services.mosquitto = {
    enable = true;
    dataDir = "/persist/mosquitto";
    listeners = [
      {
        port = 50003;
        omitPasswordAuth = true;
        settings = {
          allow_anonymous = true;
        };
        acl = [
          "topic readwrite #"
          "pattern readwrite #"
        ];
      }
    ];
  };

  services.zigbee2mqtt = {
    enable = true;
    dataDir = "/persist/zigbee2mqtt";
    settings = {
      mqtt = {
        server = "mqtt://localhost:50003";
      };
      serial = {
        port = "/dev/ttyUSB0";
      };
      advanced = {
        network_key = "!secret network_key";
      };
      frontend = {
        port = 50004;
      };
    };
  };

  hardware.bluetooth.enable = true;

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
