{ config, pkgs, lib, ... }:

let
  enableIpv6 = false;

  hostName = "nixserve";
  iotVlan = 10;

  wanInterface = {
    interface = "eno2";
    resolvers = [ "1.1.1.1" "1.0.0.1" ] ++
      (lib.optionals enableIpv6 [ "2606:4700:4700::1111" "2606:4700:4700::1001" ]);

    ipv6 = {
      naIaid = 1;
      pdIaid = 2;
      prefixLength = 56;
    };
  };

  lanInterfaces = {
    # trusted LAN
    lan = {
      interface = "eno1";
      domain = "lan.hresult.dev";

      ipv4 = {
        address = "192.168.1.1";
        prefixLength = 24;

        dhcp = {
          start = "192.168.1.100";
          end = "192.168.1.200";
          duration = "4h";
        };
      };

      ipv6 = {
        prefixLength = 64;
        slaId = 0;
      };
    };

    # untrusted IoT network
    iot = {
      interface = "iot";
      domain = "iot.hresult.dev";

      ipv4 = {
        address = "192.168.2.1";
        prefixLength = 24;

        dhcp = {
          start = "192.168.2.100";
          end = "192.168.2.200";
          duration = "1h";
        };
      };

      ipv6 = {
        prefixLength = 64;
        slaId = 1;
      };
    };
  };

  lanInterfaceList = lib.mapAttrsToList (name: interface: interface.interface) lanInterfaces;
  lanDomainsList = lib.mapAttrsToList (name: interface: interface.domain) lanInterfaces;
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;
  nix.trustedUsers = [ "ben" ];

  boot = {
    kernel.sysctl = lib.mkMerge [
      {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;

        # disable ipv6 auto configuration on interfaces by default
        "net.ipv6.conf.all.accept_ra" = 0;
      }

      (lib.mkIf enableIpv6 {
        # enable router advertisements on the wan interface
        "net.ipv6.conf.${wanInterface.interface}.accept_ra" = 2;
      })
    ];

    supportedFilesystems = [ "zfs" ];

    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/disk/by-id/usb-HP_iLO_Internal_SD-CARD_000002660A01-0:0";
    };

    kernelParams = [
      # todo: prefix length -> subnet mask
      "ip=${lanInterfaces.lan.ipv4.address}:::255.255.255.0:${hostName}:${lanInterfaces.lan.interface}:off"
    ];

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

  networking.dhcpcd = lib.mkMerge [
    {
      enable = true;
      allowInterfaces = [
        wanInterface.interface
      ];
    }

    (lib.mkIf enableIpv6 {
      extraConfig =
      let
        toPdConfig = name: interface: "${interface.interface}/${toString interface.ipv6.slaId}/${toString interface.ipv6.prefixLength}";
        wanPd = "${toString wanInterface.ipv6.pdIaid}/::/${toString wanInterface.ipv6.prefixLength}";
        lanPd = lib.concatStringsSep " " (lib.mapAttrsToList toPdConfig lanInterfaces);
      in
      ''
        # disable routing solicitation
        noipv6rs

        interface ${wanInterface.interface}
          # enable routing solicitation for wan
          ipv6rs
          # request an address for wan
          ia_na ${toString wanInterface.ipv6.naIaid}
          # request a PD and assign it to lan
          ia_pd ${wanPd} ${lanPd}
      '';
    })
  ];

  networking.interfaces =
  let
    toNetworkingInterface = interface: {
      useDHCP = false;

      ipv4 = {
        addresses = [ {
          address = interface.ipv4.address;
          prefixLength = interface.ipv4.prefixLength;
        } ];
      };
    };
  in
  (
    lib.mapAttrs' (name: interface:
      lib.nameValuePair interface.interface (toNetworkingInterface interface)
    ) lanInterfaces
  ) // {
    "${wanInterface.interface}".useDHCP = true;
  };

  # IoT interface VLAN on LAN
  networking.vlans.${lanInterfaces.iot.interface} = {
    id = iotVlan;
    interface = lanInterfaces.lan.interface;
  };

  # Disable default firewall to use nftables.
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        flowtable f {
          hook ingress priority filter; devices = { ${lib.concatStringsSep ", " [ wanInterface.interface lanInterfaces.lan.interface ]} };
        }

        chain output {
          # allow all packets sent by the router
          type filter hook output priority filter; policy accept;
        }

        chain input {
          type filter hook input priority filter; policy drop;

          # icmp flood protection
          meta l4proto icmp icmp type { echo-request } limit rate over 10/second drop
          meta l4proto ipv6-icmp icmpv6 type { echo-request } limit rate over 10/second drop

          # early drop invalid connections
          ct state invalid drop

          # allow established/related connections
          ct state { established, related } accept

          # allow from lo
          iifname { lo } accept

          # allow essential icmp
          meta l4proto icmp icmp type { destination-unreachable, time-exceeded, parameter-problem } accept

          # allow icmp ping
          meta l4proto icmp icmp type { echo-request, echo-reply } accept

          # allow icmp router selection
          meta l4proto icmp icmp type { router-solicitation, router-advertisement } accept

          # rfc4890 4.4.1 - allow essential icmpv6
          meta l4proto ipv6-icmp icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem } accept

          # rfc4890 4.4.1 - allow icmpv6 ping
          meta l4proto ipv6-icmp icmpv6 type { echo-request, echo-reply } accept

          # rfc4890 4.4.1 - allow icmpv6 addess configuration and router selection
          meta l4proto ipv6-icmp icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, ind-neighbor-solicit, ind-neighbor-advert } ip6 hoplimit 255 accept

          # rfc4890 4.4.1 - allow icmpv6 link-local multicast receiver notification messages
          meta l4proto ipv6-icmp icmpv6 type { mld-listener-query, mld-listener-report, mld-listener-done, mld2-listener-report } ip6 saddr fe80::/10 accept

          # rfc4890 4.4.1 - allow icmpv6 send certificate path notification messages
          meta l4proto ipv6-icmp icmpv6 type { 148, 149 } ip6 hoplimit 255 accept

          # rfc4890 4.4.1 - allow icmpv6 multicast router discovery messages
          meta l4proto ipv6-icmp icmpv6 type { 151, 152, 153 } ip6 hoplimit 1 ip6 saddr fe80::/10 accept

          # allow igmp
          ip protocol igmp accept

          # per if rules
          iifname ${wanInterface.interface} jump input_wan
          iifname ${lanInterfaces.lan.interface} jump input_lan
          iifname ${lanInterfaces.iot.interface} jump input_iot

          # refuse unexpected traffic
          reject with icmp type port-unreachable
        }

        chain input_wan {
          # router dhcp client
          ip6 saddr fe80::/10 ip6 daddr fe80::/10 udp dport { dhcpv6-client } udp sport { dhcpv6-server } accept

          # allow ssh - rate limited per ip
          tcp dport { ssh } ct state new flow table ssh-ftable { ip saddr limit rate 2/minute } accept

          # allow http and https
          tcp dport { http, https } accept
          udp dport { http, https } accept
        }

        chain input_lan {
          # allow http and https
          tcp dport { http, https } accept
          udp dport { http, https } accept

          # allow ssh
          tcp dport { ssh } accept

          # allow dns
          tcp dport { domain } accept
          udp dport { domain } accept

          # allow mdns
          tcp dport { llmnr } counter accept
          udp dport { mdns, llmnr } counter accept

          # allow dhcp
          udp dport { bootps } udp sport { bootpc } accept

          # allow dhcpv6
          ip6 saddr fe80::/10 ip6 daddr fe80::/10 udp dport { dhcpv6-server } udp sport { dhcpv6-client } accept

          # accept ipp ( printing )
          tcp dport { ipp } accept

          # accept samba related traffic
          udp dport { netbios-ns, netbios-dgm } accept
          tcp dport { netbios-ssn, microsoft-ds } accept
        }

        chain input_iot {
          # allow dns
          tcp dport { domain } accept
          udp dport { domain } accept

          # allow mdns
          tcp dport { llmnr } counter accept
          udp dport { mdns, llmnr } counter accept

          # allow dhcp
          udp dport { bootps } udp sport { bootpc } accept

          # allow dhcpv6
          ip6 saddr fe80::/10 ip6 daddr fe80::/10 udp dport { dhcpv6-server } udp sport { dhcpv6-client } accept
        }

        chain forward {
          type filter hook forward priority filter; policy drop;

          # offload established connections
          ip protocol { tcp, udp } flow offload @f

          # allow lan -> wan
          iifname ${lanInterfaces.lan.interface} oifname ${wanInterface.interface} accept

          # allow lan -> iot
          iifname ${lanInterfaces.lan.interface} oifname ${lanInterfaces.iot.interface} accept

          # icmp flood protection
          meta l4proto icmp icmp type { echo-request } limit rate over 10/second drop
          meta l4proto ipv6-icmp icmpv6 type { echo-request } limit rate over 10/second drop

          # allow iot -> wan
          iifname ${lanInterfaces.iot.interface} oifname ${wanInterface.interface} accept

          # allow established wan return -> lan
          iifname ${wanInterface.interface} oifname ${lanInterfaces.lan.interface} ct state { established, related } accept

          # allow established wan return -> iot
          iifname ${wanInterface.interface} oifname ${lanInterfaces.iot.interface} ct state { established, related } accept

          # allow established iot return -> lan
          iifname ${lanInterfaces.iot.interface} oifname ${lanInterfaces.lan.interface} ct state { established, related } accept

          # rfc4890 4.3.1 - allow icmpv6 ping
          meta l4proto ipv6-icmp icmpv6 type { echo-request } accept
        }
      }

      table inet nat {
        chain prerouting {
          type nat hook prerouting priority filter; policy accept;

          # force all dns queries to use local resolver
          iifname { ${lib.concatStringsSep ", " lanInterfaceList} } tcp dport { domain } redirect
          iifname { ${lib.concatStringsSep ", " lanInterfaceList} } udp dport { domain } redirect
        }

        chain postrouting {
          type nat hook postrouting priority filter; policy accept;

          # setup nat masquerading on the wan interface for ipv4
          meta nfproto ipv4 oifname ${wanInterface.interface} masquerade
        }
      }
    '';
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    extraConfig =
    let
      toDnsmasqConfig = name: interface: (''
        # bind to ${name} interface
        interface=${interface.interface}

        # dhcp configuration
        dhcp-range=${interface.ipv4.dhcp.start},${interface.ipv4.dhcp.end},${interface.ipv4.dhcp.duration}

        # specifies the domain name for this network
        domain=${interface.domain},${interface.ipv4.address}/${toString interface.ipv4.prefixLength}

        # ensure that this machine resolves on each domain - todo: aaaa?
        address=/${hostName}.${interface.domain}/${interface.ipv4.address}
      '' + (lib.optionalString enableIpv6 ''
        dhcp-range=::,constructor:${interface.interface},ra-stateless,ra-names
      ''));
      domainSearchList = lib.concatStringsSep "," lanDomainsList;
    in
    ''
      # dnsmasq should bind to avoid firewall issues
      bind-interfaces

      # this is the only dhcp server on the network
      dhcp-authoritative

      # configure dhcpv4
      dhcp-option=option:domain-search,${domainSearchList}
      dhcp-option=option:dns-server,0.0.0.0
      dhcp-option=option:router,0.0.0.0

      # do not resolve dns queries from upstream or the hosts file
      no-resolv
      no-hosts

      # dns should listen on 15353 as coredns is used as the forwarder
      port=15353
      # any addresses not answered from dhcp return NXDOMAIN
      address=/#/
    '' + (lib.optionalString enableIpv6 ''
      # enable router advertisements
      enable-ra

      # configure dhcpv6 - todo: configure ULAs
      dhcp-option=option6:domain-search,${domainSearchList}
      dhcp-option=option6:dns-server,[::]
    '') + (lib.concatStringsSep "\n" (lib.mapAttrsToList toDnsmasqConfig lanInterfaces));
  };

  services.coredns = {
    enable = true;
    config = ''
      # forward any queries on the internal domains to dnsmasq
      ${lib.concatStringsSep " " lanDomainsList} {
        forward . dns://127.0.0.1:15353
      }

      # all other queries should be forwarded to an external dns provider
      . {
        # a random upstream will be selected - so long as it is healthy
        forward . ${lib.concatMapStringsSep " " (x: "tls://" + x) wanInterface.resolvers} {
          tls_servername cloudflare-dns.com
          health_check 5s
        }

        # caches all dns queries but caps TTL to 5 mins
        cache 300
      }
    '';
  };

  networking.resolvconf.useLocalResolver = true;

  # Use UTC for servers.
  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  # Use agent forwarding for sudo.
  security.pam.enableSSHAgentAuth = true;
  security.sudo.enable = true;

  services.caddy = {
    enable = true;
    package = pkgs.caddyExtra;
    environmentFile = "/etc/secrets/caddy.secret";
    config =
    let
      common = ''
        tls {
          protocols tls1.2 tls1.3
          ciphers TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
          resolvers ${lib.concatStringsSep " " wanInterface.resolvers}
        }

        header {
          Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
          defer
        }

        encode gzip
      '';
    in
    ''
      {
        email ben@curlybracket.co.uk
        acme_dns cloudflare {env.CF_API_TOKEN}
      }

      bw.benpye.uk {
        ${common}

        reverse_proxy /notifications/hub http://localhost:3012

        reverse_proxy http://localhost:8000 {
          header_up X-Real-IP {remote_host}
        }
      }

      lounge.benpye.uk {
        ${common}

        reverse_proxy http://localhost:9000
      }

      miniflux.benpye.uk {
        ${common}

        reverse_proxy http://localhost:9090
      }
      '';
  };

  services.avahi = {
    enable = true;
    cacheEntriesMax = 0;
    publish = {
      enable = true;
      userServices = true;
    };
    reflector = true;
    interfaces = lanInterfaceList;
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
        name = "bitwarden_rs";
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

  services.bitwarden_rs = {
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
      s3CredentialsFile = "/etc/secrets/restic/media/b2_credentials";
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

  environment.systemPackages =
    [
      pkgs.nftables
    ];

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
