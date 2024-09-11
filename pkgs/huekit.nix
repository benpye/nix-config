{
  stdenv,
  lib,
  pkgs,
  buildGoModule,
}:

buildGoModule rec {
  name = "huekit";
  version = "4e321f4dc064c03c66186be5bf6ada0f12e1ba85";
  vendorSha256 = "sha256-tiR6DsW6Niu0hupMoXRtXN1OlLDlIgYJD76GOpsSiXE=";
  subPackages = [ "cmd/huekit" ];

  src = pkgs.fetchFromGitHub {
    owner = "dj95";
    repo = name;
    rev = version;
    sha256 = "sha256-Ri2CtddIScgU9YweET6MxKOMqqGkq1v0EBP54+b4Ud4=";
  };
}
