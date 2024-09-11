{ pkgs }:
let
  inherit (pkgs.stdenv) hostPlatform;

  loadModule = file: { condition ? true }: {
    inherit file condition;
  };

  modules = [ ];
in
map (builtins.getAttr "file") (builtins.filter (builtins.getAttr "condition") modules)
