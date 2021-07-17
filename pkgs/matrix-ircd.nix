{ stdenv, lib, pkgs, rustPlatform, pkg-config, openssl }:

rustPlatform.buildRustPackage rec {
  pname = "matrix-ircd";
  version = "cdf5fc70471d21c8d631e98ef19e04de83f27390";

  src = pkgs.fetchFromGitHub {
    owner = "matrix-org";
    repo = pname;
    rev = version;
    sha256 = "0krfgwgn3hlrkppfwpprfba1wpawki6fprx0wbc53fkc110bwzp5";
  };

  cargoSha256 = "0wa5lw4rkplvkggcmvqdcch2l2gx5ns3wpypnmv8q1xpja6h72gl";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "An IRCd implementation backed by Matrix.";
    homepage = "https://github.com/matrix-org/matrix-ircd";
    license = licenses.asl20;
    maintainers = [ maintainers.benpye ];
  };
}
