{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot = {
    loader.systemd-boot = {
      enable = true;
      consoleMode = "max";
    };

    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = [ "zfs" ];

    # Reserve Nvidia GPU for VFIO only
    kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
    extraModprobeConfig ="options vfio-pci ids=10de:1b81,10de:10f0";

    # Required for SR-IOV
    kernelParams = [ "pci=realloc,assign-busses" ];
  };

  hardware.video.hidpi.enable = false;

  networking = {
    hostName = "nixtop";
    hostId = "0d2065ec";
  };

  networking.useDHCP = false;
  networking.interfaces.enp1s0f0.useDHCP = true;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = ( lib.range 1714 1764 ) ++ [ 5353 50000 ];
  networking.firewall.allowedUDPPorts = ( lib.range 1714 1764 ) ++ [ 5353 ];

  time.timeZone = "America/Vancouver";

  # typically using a UK keyboard
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  # x11 config for monitor layout and gsync
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];

    displayManager.sddm = {
      enable = true;

      settings = {
        General = {
          # DisplayServer = "wayland";
          GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell"; #,QT_LOGGING_RULES=kwin_*.debug=true";
          InputMethod = "";
        };

        Wayland = {
          CompositorCommand = "kwin_wayland --no-lockscreen --inputmethod qtvirtualkeyboard";
        };
      };
    };

    desktopManager.plasma5 = {
      enable = true;
      runUsingSystemd = true;
    };
  };

  programs.xwayland.enable = true;

  services.xserver.dpi = 96;

  # ensure that 32-bit graphics and audio libraries are available
  hardware.opengl.driSupport32Bit = true;

  # uk keyboard layout as above
  services.xserver.layout = "gb";

  services.udev.packages = [ pkgs.yubikey-personalization pkgs.xilinx-udev-rules ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.rpcbind.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", ENV{ID_NET_DRIVER}=="ixgbe", ATTR{device/sriov_numvfs}="4"
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };

  # Add ZFS for zpool support.
  systemd.services.libvirtd.path = [ pkgs.zfs ];

  programs.dconf.enable = true;
  programs.wireshark.enable = true;

  environment.systemPackages = [
    pkgs.virt-manager
  ];

  users.users.ben = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "wireshark" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

