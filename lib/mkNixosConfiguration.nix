{ nixos
, name
, system
, overlays ? []
, imports ? [] }:

let
  pkgs = nixos.outputs.legacyPackages.${system};
in
nixos.lib.nixosSystem {
  inherit system;
  modules = [
    nixos.nixosModules.notDetected
    ({ nixpkgs.overlays = [ (import ../pkgs) ] ++ (import ../overlays) ++ overlays; })
    (../machine + "/${name}")
  ] ++ (import ../modules { inherit pkgs; });
}
