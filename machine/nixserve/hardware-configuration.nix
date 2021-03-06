# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "uhci_hcd" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "tank/system/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/57103dd7-e88f-4dca-aed0-e824a86020aa";
      fsType = "ext4";
    };

  fileSystems."/home" =
    { device = "tank/system/safe/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "tank/system/safe/persist";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "tank/system/local/nix";
      fsType = "zfs";
    };

  fileSystems."/tank" =
    { device = "tank";
      fsType = "zfs";
    };

  fileSystems."/tank/library" =
    { device = "tank/library";
      fsType = "zfs";
    };

  fileSystems."/tank/library/lightroom" =
    { device = "tank/library/lightroom";
      fsType = "zfs";
    };

  fileSystems."/tank/library/photos" =
    { device = "tank/library/photos";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/91c3108c-cb55-463f-8790-fc411064eaa2"; }
    ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
