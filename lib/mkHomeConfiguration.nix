{ home-manager
, name
, system
, username
, homeDirectory ? null
, overlays ? []
, imports ? [] }:

let
  pkgs = home-manager.inputs.nixpkgs.outputs.legacyPackages.${system};
  homeDirectory' = if homeDirectory == null then
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}"
    else "/home/${username}"
  else homeDirectory;
in
home-manager.lib.homeManagerConfiguration {
  configuration = {
    nixpkgs.overlays = [ (import ../pkgs) ] ++ (import ../overlays) ++ overlays;
    imports = [ (../home + "/${name}") ] ++ (import ../hm { inherit pkgs; });
  };
  homeDirectory = homeDirectory';
  inherit system username pkgs;
}
