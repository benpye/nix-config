self: super:
{
  matrix-ircd = super.callPackage ./matrix-ircd.nix {};
  ncspot = super.callPackage ./ncspot.nix {
    withMPRIS = super.stdenv.isLinux;
    withCover = super.stdenv.isLinux;
  };
}
