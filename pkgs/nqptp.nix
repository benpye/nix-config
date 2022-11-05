{ stdenv, lib, pkgs, fetchurl, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "nqptp";
  version = "c71b49a3556ba8547ee28482cb31a97fe99298aa";

  src = pkgs.fetchFromGitHub {
    owner = "mikebrady";
    repo = name;
    rev = version;
    sha256 = "sha256-ea1cutXDhCIWtXn054eRQ/rg1+4M8cWBtN9e9s3pVys=";
  };

  nativeBuildInputs = [ autoreconfHook ];
}
