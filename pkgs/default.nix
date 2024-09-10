self: super:
{
  beets-importreplace = super.callPackage ./beets-importreplace.nix { beets = super.beetsPackages.beets-minimal; };
  huekit = super.callPackage ./huekit.nix {};
  nqptp = super.callPackage ./nqptp.nix {};
  promscale = super.callPackage ./promscale {};
  shairport-airplay2 = super.callPackage ./shairport-airplay2.nix {};
  vuescan = super.callPackage ./vuescan.nix {};
}
