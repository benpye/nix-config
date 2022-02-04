{ pkgs }:
let
  inherit (pkgs.stdenv) hostPlatform;

  loadModule = file: { condition ? true }: {
    inherit file condition;
  };

  modules = [
    (loadModule ./services/hkrm4.nix { })
    (loadModule ./services/huekit.nix { })
  ];
in
map (builtins.getAttr "file") (builtins.filter (builtins.getAttr "condition") modules)
