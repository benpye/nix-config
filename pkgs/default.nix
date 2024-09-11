self: super: {
  beets-importreplace = super.callPackage ./beets-importreplace.nix {
    beets = super.beetsPackages.beets-minimal;
  };
  huekit = super.callPackage ./huekit.nix { };
  vuescan = super.callPackage ./vuescan.nix { };
}
