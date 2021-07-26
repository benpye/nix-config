{ config, pkgs, ... }:

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
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "nixtop";
    hostId = "0d2065ec";
  };

  networking.useDHCP = false;
  networking.interfaces.enp4s0.useDHCP = true;

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
    videoDrivers = [ "nvidia" ];
    screenSection = ''
      Option "metamodes" "DP-2: nvidia-auto-select +0+0 {AllowGSYNCCompatible=On}, DP-4: nvidia-auto-select +2560+0"
    '';
    xrandrHeads = [
      "DP-2"
      "DP-4"
    ];

    # need to enable xterm so i3 can start from lightdm
    desktopManager.xterm.enable = true;
  };

  # ensure that 32-bit graphics libraries are available
  hardware.opengl.driSupport32Bit = true;

  # uk keyboard layout as above
  services.xserver.layout = "gb";

  services.udev.packages = [ pkgs.yubikey-personalization ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  users.users.ben = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

