{ config, pkgs, ... }:

rec {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.trustedUsers = [ "ben" ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.extraConfig = ''
    serial --unit=1 --speed=115200 --word=8 --parity=no --stop=1
    terminal_input --append serial
    terminal_output --append serial
  '';

  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda";

  # Use Linux 5.15 with the VeloCloud modules.
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_5_15;
  boot.extraModulePackages = [ (pkgs.velocloud-modules.override {
    kernel = boot.kernelPackages.kernel;
  }) ];

  # Serial on ttyS1.
  boot.kernelParams = [ "console=ttyS1,115200n8" "acpi_enforce_resources=lax" ];

  # The required kernel modules for Ethernet, fan and LED control.
  boot.initrd.kernelModules = [ "lpc_ich" "velocloud-edge-5x0" ];
  boot.initrd.availableKernelModules = [ "gpio_ich" "iTCO_wdt" ];

  networking = {
    hostName = "routenix";
    hostId = "3b8c16d1";
  };

  # Set your time zone.
  time.timeZone = "UTC";

  networking.useDHCP = false;
  networking.interfaces.enp0s20f2.useDHCP = true;
  networking.interfaces.enp0s20f3.useDHCP = true;
  networking.interfaces.enp4s0f0.useDHCP = false;
  networking.interfaces.enp4s0f1.useDHCP = false;
  networking.interfaces.wlp2s0.useDHCP = false;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ ];

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

