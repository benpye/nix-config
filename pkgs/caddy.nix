{ stdenv, lib, pkgs, buildGoModule, plugins ? [], vendorSha256 ? "" }:

with lib;

  let
    requires = flip concatMapStrings plugins (pkg: "go get ${pkg.url}@${pkg.rev}\n");
    imports = flip concatMapStrings plugins (pkg: "_ \"${pkg.url}\"\n");
    main = ''
      package main

      import (
        caddycmd "github.com/caddyserver/caddy/v2/cmd"

        _ "github.com/caddyserver/caddy/v2/modules/standard"
        ${imports}
      )

      func main() {
        caddycmd.Main()
      }
  '';

in buildGoModule rec {
  pname = "caddy";
  version = "2.4.0-beta.2";

  subPackages = [ "cmd/caddy" ];

  src = pkgs.fetchFromGitHub {
    owner = "caddyserver";
    repo = pname;
    rev = "v${version}";
    sha256 = "0x1libpabdwbz9rkwzc3w2anmhbg4q73460b3l983cih4x9zcns8";
  };

  inherit vendorSha256;

  overrideModAttrs = (_: {
    inherit postPatch;
    preBuild = "${requires}";
    postInstall = "cp go.sum go.mod $out/";
  });

  postPatch = ''
    echo '${main}' > cmd/caddy/main.go
  '';

  postConfigure = ''
    cp vendor/go.sum ./
    cp vendor/go.mod ./
  '';

  meta = with pkgs.lib; {
    homepage = https://caddyserver.com;
    description = "Fast, cross-platform HTTP/2 web server with automatic HTTPS";
    license = licenses.asl20;
    maintainers = with maintainers; [ rushmorem fpletz zimbatm ];
  };
}
