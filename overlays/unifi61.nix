self: super:
{
  unifi61 = super.unifiStable.overrideAttrs (oldAttrs: rec {
    version = "6.1.61";
    sha256 = "sha256-65i/Yyqil4jYfiHsYp/aLkwGq4Bpssr0UE4DQddp2JI=";
    suffix = "-5b1c34fbe3";
    src = super.fetchurl {
      url = "https://dl.ubnt.com/unifi/${version}${suffix}/unifi_sysvinit_all.deb";
      inherit sha256;
    };
  });
}
