{ ... }:
let
  mkHomeConfiguration = import ./mkHomeConfiguration.nix;
  mkNixosConfiguration = import ./mkNixosConfiguration.nix;
in
{
  mkHomeConfigurations =
    builtins.mapAttrs (name: value: mkHomeConfiguration (value // { inherit name; }));

  mkNixosConfigurations =
    builtins.mapAttrs (name: value: mkNixosConfiguration (value // { inherit name; }));
}
