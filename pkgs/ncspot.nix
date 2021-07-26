{ stdenv, lib, fetchFromGitHub, rustPlatform, pkg-config, openssl, libiconv, makeWrapper
, alsa-lib ? null
, withMPRIS ? false, dbus ? null
, withCover ? false, ueberzug ? null
}:

let
  features = [ "termion_backend" "rodio_backend" "notify" ]
    ++ lib.optional withMPRIS "mpris"
    ++ lib.optional withCover "cover";
in
rustPlatform.buildRustPackage rec {
  pname = "ncspot";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "hrkfdn";
    repo = "ncspot";
    rev = "v${version}";
    sha256 = "0lfly3d8pag78pabmna4i6xjwzi65dx1mwfmsk7nx64brq3iypbq";
  };

  cargoSha256 = "0a6d41ll90fza6k3lixjqzwxim98q6zbkqa3zvxvs7q5ydzg8nsp";

  cargoBuildFlags = [ "--no-default-features" "--features" "${lib.concatStringsSep "," features}" ];

  nativeBuildInputs = [ makeWrapper pkg-config ];

  buildInputs = [ openssl ]
    ++ lib.optional stdenv.isDarwin libiconv
    ++ lib.optional stdenv.isLinux alsa-lib
    ++ lib.optional withMPRIS dbus;

  postInstall = ''
    wrapProgram $out/bin/ncspot \
      --prefix PATH : ${lib.makeBinPath ([] ++ lib.optional withCover ueberzug) }
  '';

  doCheck = false;

  meta = with lib; {
    description = "Cross-platform ncurses Spotify client written in Rust, inspired by ncmpc and the likes";
    homepage = "https://github.com/hrkfdn/ncspot";
    license = licenses.bsd2;
    maintainers = [ maintainers.marsam ];
  };
}
