{ pkgs }:
let
  hostPlatform = pkgs.stdenv.hostPlatform;

  loadModule = file: { condition ? true }: {
    inherit file condition;
  };

  modules = [
    (loadModule ./agents/dirmngr.nix { condition = hostPlatform.isDarwin; })
    (loadModule ./agents/gpg-agent.nix { condition = hostPlatform.isDarwin; })

    (loadModule ./disable-systemd.nix { condition = hostPlatform.isDarwin; })
    (loadModule ./launchd { condition = hostPlatform.isDarwin; })
  ];
in
map (builtins.getAttr "file") (builtins.filter (builtins.getAttr "condition") modules)
