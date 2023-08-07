{ home-manager
, name
, system
, username
, homeDirectory ? null
, overlays ? []
, imports ? []
, stateVersion }:

let
  pkgs = home-manager.inputs.nixpkgs.outputs.legacyPackages.${system};
  homeDirectory' = if homeDirectory == null then
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}"
    else "/home/${username}"
  else homeDirectory;
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    {
      nixpkgs.overlays = [ (import ../pkgs) ] ++ (import ../overlays) ++ overlays;
      imports = [ (../home + "/${name}") ] ++ (import ../hm { inherit pkgs; });
      disabledModules = [ ] ++ pkgs.lib.optionals (pkgs.hostPlatform.isDarwin) [ "services/gpg-agent.nix" ];
      home = {
        homeDirectory = homeDirectory';
        inherit username stateVersion;
      };
    }
  ];
}
