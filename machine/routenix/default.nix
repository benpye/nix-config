{ config, lib, pkgs, ... }:

let
  lan = "enp0s20f2";
  wan = "enp0s20f3";

in rec
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.trustedUsers = [ "ben" ];

  boot = {
    # Use the GRUB 2 boot loader.
    loader.grub = {
      enable = true;
      version = 2;
      extraConfig = ''
        serial --unit=1 --speed=115200 --word=8 --parity=no --stop=1
        terminal_input --append serial
        terminal_output --append serial
      '';

      # Define on which hard drive you want to install Grub.
      device = "/dev/sda";
    };

    # Use Linux 5.15 with the VeloCloud modules.
    kernelPackages = pkgs.linuxKernel.packages.linux_5_15;
    extraModulePackages = [ (pkgs.velocloud-modules.override {
      kernel = boot.kernelPackages.kernel;
    }) ];

    # Serial on ttyS1.
    kernelParams = [ "console=ttyS1,115200n8" "acpi_enforce_resources=lax" ];

    # The required kernel modules for Ethernet, fan and LED control.
    initrd = {
      kernelModules = [ "lpc_ich" "velocloud-edge-5x0" ];
      availableKernelModules = [ "gpio_ich" "iTCO_wdt" ];
    };

    kernel.sysctl = {
      # Enable IPv4 and IPv6 forwarding.
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;

      # Disable IPv6 autoconfiguration by default.
      "net.ipv6.conf.all.accept_ra" = 0;

      # Enable RA on the WAN interface.
      "net.ipv6.conf.${wan}.accept_ra" = 2;
    };
  };

  # Set your time zone.
  time.timeZone = "UTC";

  networking = {
    hostName = "routenix";
    hostId = "3b8c16d1";

    nameservers = [ "1.1.1.1" "1.0.0.1" ];

    useDHCP = false;

    interfaces = {
      # Unused interfaces.
      enp4s0f0.useDHCP = false;
      enp4s0f1.useDHCP = false;
      wlp2s0.useDHCP = false;

      ${lan} = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.1.1";
          prefixLength = 24;
        }];
      };

      ${wan} = {
        useDHCP = true;
      };
    };

    dhcpcd = {
      extraConfig = ''
        # disable routing solicitation by default
        noipv6rs

        # use a DUID - hopefully results in the same lease
        duid

        interface ${wan}
          # enable routing solicitation for wan
          ipv6rs
          # request a prefix for lan
          ia_pd 0 ${lan}/0
      '';

      # Update Cloudflare DNS record on DHCP event.
      runHook = ''
        if [ "$reason" = BOUND ] || [ "$reason" = RENEW ] || [ "$reason" = REBIND ] || [ "$reason" = REBOOT ]; then
          ${pkgs.curl}/bin/curl -X PATCH "https://api.cloudflare.com/client/v4/zones/cd22faa3ccb393ec2d2717cd574eba11/dns_records/5a15ed0011443e26a07b49b3c2c4e8a1" \
            --config /etc/secrets/ddns.secret \
            -H "Content-Type: application/json" \
            --data '{ "type": "A", "name": "nixserve.benpye.uk", "content": "'$new_ip_address'", "ttl": 1, "proxied": true }'
        fi
      '';
    };

    # Default default firewall in favour of nftables.
    firewall.enable = false;

    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          flowtable f {
            hook ingress priority filter; devices = { ${lib.concatStringsSep ", " [ wan lan ]} };
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
            iifname ${wan} jump input_wan
            iifname ${lan} jump input_lan

            # refuse unexpected traffic
            reject with icmp type port-unreachable
          }

          chain input_wan {
            # router dhcp client
            ip6 saddr fe80::/10 ip6 daddr fe80::/10 udp dport { dhcpv6-client } udp sport { dhcpv6-server } accept

            # allow ssh - rate limited per ip
            tcp dport { ssh } ct state new flow table ssh-ftable { ip saddr limit rate 2/minute } accept
          }

          chain input_lan {
            # allow ssh
            tcp dport { ssh } accept

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
            iifname ${lan} oifname ${wan} accept

            # icmp flood protection
            meta l4proto icmp icmp type { echo-request } limit rate over 10/second drop
            meta l4proto ipv6-icmp icmpv6 type { echo-request } limit rate over 10/second drop

            # allow established wan return -> lan
            iifname ${wan} oifname ${lan} ct state { established, related } accept

            # rfc4890 4.3.1 - allow icmpv6 ping
            meta l4proto ipv6-icmp icmpv6 type { echo-request } accept

            # allow dnat traffic
            ct status dnat accept
          }
        }

        table inet nat {
          chain prerouting {
            type nat hook prerouting priority filter; policy accept;

            # port forward nixserve http, https
            meta nfproto ipv4 iifname ${wan} tcp dport { http, https } dnat to 192.168.1.20;
            meta nfproto ipv4 iifname ${wan} udp dport { http, https } dnat to 192.168.1.20;
          }

          chain postrouting {
            type nat hook postrouting priority filter; policy accept;

            # setup nat masquerading on the wan interface for ipv4
            meta nfproto ipv4 oifname ${wan} masquerade
          }
        }
      '';
    };
  };

  # Periodically perform router discovery. Upstream router does not send RA
  # at a regular interval.
  systemd.services.rdisc6 = {
    description = "Periodic ICMPv6 router discovery service.";
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      AmbientCapabilities = "CAP_NET_RAW";
      ExecStart = "${pkgs.ndisc6}/bin/rdisc6 --single ${wan}";
    };
  };

  systemd.timers.rdisc6 = {
    description = "Periodic ICMPv6 router discovery timer.";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15m";
      OnUnitActiveSec = "15m";
      Persistent = true;
    };
  };

  # Enable DHCPv4 server.
  services.dhcpd4 = {
    enable = true;
    interfaces = [ lan ];

    machines = [
      {
        ethernetAddress = "94:18:82:37:5f:a9";
        hostName = "nixserve";
        ipAddress = "192.168.1.20";
      }
    ];

    extraConfig = ''
      option subnet-mask 255.255.255.0;
      option broadcast-address 192.168.1.255;
      option routers 192.168.1.1;
      option domain-name-servers 1.1.1.1, 1.0.0.1;
      option domain-name "int.hresult.dev";
      subnet 192.168.1.0 netmask 255.255.255.0 {
        range 192.168.1.100 192.168.1.200;
      }
    '';
  };

  # Enable Router Advertisement daemon.
  services.radvd = {
    enable = true;
    config = ''
    interface ${lan}
    {
      # enable ra on lan
      AdvSendAdvert on;

      prefix ::/64 {
        AdvOnLink on;
        AdvAutonomous on;
      };

      RDNSS 2606:4700:4700::1111 2606:4700:4700::1001 {
      };

      DNSSL int.hresult.dev {
      };
    };
    '';
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Use agent forwarding for sudo.
  security.pam.enableSSHAgentAuth = true;
  security.sudo.enable = true;

  users.users = {
    ben = {
      extraGroups = [ "wheel" ];
      uid = 1000;
      isNormalUser = true;
      openssh.authorizedKeys.keys =
        [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDU7W3aX/Crbp4bKNRNZWRYaxgpH6tsjt88l6jspdlHToMz6Vvq4NU7CHwXNBijO0LTh7wxeKT3E5DZkPepE9gv7vRIrSX5NLHlLLAibC6iogF70SGqLeyEUXh70tMa+ZxU6wow5VcGxZ0RBXsuunKFhGqatveRaw6CbIYceLvnJvUBcsw0M3tr6EtyuTQ2p8BFoZNnYX+4Aj3HAz/uuwjUcgz3ri+Ot+yJKjkS2dV/aKCznQhvS3sX8Fio3eBI7XBm8oc5O1jI37y4Tckq/mnQORiTaKTvkbZmRojPgk7EdjACJJPVfk2mCnl/zcShQDyzOz5BhUOCvOObeJWseBp3"
        ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

