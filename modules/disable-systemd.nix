{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    systemd.user = {
      services = mkOption {
        apply = _: { };
      };

      slices = mkOption {
        apply = _: { };
      };

      sockets = mkOption {
        apply = _: { };
      };

      targets = mkOption {
        apply = _: { };
      };

      timers = mkOption {
        apply = _: { };
      };

      paths = mkOption {
        apply = _: { };
      };

      mounts = mkOption {
        apply = _: { };
      };

      sessionVariables = mkOption {
        apply = _: { };
      };
    };
  };
}
