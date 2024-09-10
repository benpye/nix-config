{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot = {
    loader.systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };

    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = [ "zfs" ];

    # Required for SR-IOV
    kernelParams = [ "pci=realloc,assign-busses" ];

    # Reserve Nvidia GPU for VFIO only
    kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
    extraModprobeConfig ="options vfio-pci ids=10de:1b81,10de:10f0";

    # Apparently needed for video out?
    initrd.kernelModules = [ "amdgpu" ];
  };

  networking = {
    hostName = "hydrogen";
    hostId = "a76faf31";
  };

  networking.useDHCP = false;
  networking.interfaces.enp1s0f0.useDHCP = true;

  networking.firewall.enable = true;

  time.timeZone = "America/Vancouver";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
  };

  services.displayManager.sddm = {
    enable = true;
    settings = {
      General = {
        GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
      };
      Wayland = {
        CompositorCommand = "${pkgs.kdePackages.kwin}/bin/kwin_wayland_wrapper --no-lockscreen --no-global-shortcuts --locale1";
      };
    };
    wayland = {
      enable = true;
    };
  };

  environment.systemPackages = [
    pkgs.kdePackages.layer-shell-qt
    pkgs.virt-manager
  ];

  services.desktopManager.plasma6.enable = true;

  # hardware.nvidia = {
  #   package = config.boot.kernelPackages.nvidiaPackages.beta;
  #   modesetting.enable = false; #true;
  #   powerManagement.enable = false; #true;
  # };

  programs.xwayland.enable = true;

  services.udev.packages = [ pkgs.yubikey-personalization pkgs.vuescan ]; # pkgs.xilinx-udev-rules ];

  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.services.swaylock = {};

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", ENV{ID_NET_DRIVER}=="ixgbe", ATTR{device/sriov_numvfs}="4"
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = false;
      swtpm.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  # Add ZFS for zpool support.
  systemd.services.libvirtd.path = [ pkgs.zfs ];

  users.users.ben = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  users.users.qemu-libvirtd = {
    extraGroups = [ "input" ];
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

