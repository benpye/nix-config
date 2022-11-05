self: super:
{
  huekit = super.callPackage ./huekit.nix {};
  nqptp = super.callPackage ./nqptp.nix {};
  promscale = super.callPackage ./promscale {};
  shairport-airplay2 = super.callPackage ./shairport-airplay2.nix {};
}
