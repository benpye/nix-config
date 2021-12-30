{ pkgs }:
let
  hostPlatform = pkgs.stdenv.hostPlatform;

  loadModule = file: { condition ? true }: {
    inherit file condition;
  };

  modules = [
    (loadModule ./services/matrix-ircd.nix {})
    (loadModule ./services/miniflux.nix { })
  ];
in
map (builtins.getAttr "file") (builtins.filter (builtins.getAttr "condition") modules)
