self: super:
{
  huekit = super.callPackage ./huekit.nix {};
  promscale = super.callPackage ./promscale {};
}
