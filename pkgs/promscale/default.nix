{ stdenv, lib, pkgs, buildGoModule }:

buildGoModule rec {
  pname = "promscale";
  version = "0.9.0";

  src = pkgs.fetchFromGitHub {
    owner = "timescale";
    repo = pname;
    rev = version;
    sha256 = "sha256-snbQVkJ4J5ElVNfHuSfb7VCZ64TqJ8Lx5uUaJPqBHl4=";
  };

  patches = [
    ./0001-remove-jaeger-test-dep.patch
  ];

  subPackages = [ "./cmd/promscale" ];

  vendorSha256 = "sha256-1t4WNoJrfKTtrpwi9p+L1WQR7mTsD70CRW+RYT7E9Lo=";

  CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/timescale/promscale/pkg/version.CommitHash=${src.rev}"
    "-X github.com/timescale/promscale/pkg/telemetry.BuildPlatform=nix"
  ];

  doCheck = false;
}
