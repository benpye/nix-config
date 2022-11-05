{ lib, stdenv, fetchFromGitHub
, autoreconfHook, pkg-config
, openssl, avahi, alsa-lib, glib, libdaemon, popt, libconfig, libpulseaudio, soxr
, libplist, libsodium, ffmpeg, libuuid, libgcrypt, unixtools
}:

with lib;
stdenv.mkDerivation rec {
  version = "e7c6c4b2064506c8b635e0925700c561609baff3";
  pname = "shairport-sync";

  src = fetchFromGitHub {
    sha256 = "sha256-YcwueJ5rojQe/GaxTLLJBfLbIYc2IeomCNn5CjVvv38=";
    rev = version;
    repo = "shairport-sync";
    owner = "mikebrady";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config unixtools.xxd ];

  buildInputs = [
    openssl
    avahi
    alsa-lib
    libdaemon
    popt
    libconfig
    soxr
    glib
    libplist
    libsodium
    ffmpeg
    libuuid
    libgcrypt
  ];

  enableParallelBuilding = true;

  configureFlags = [
    "--with-alsa" "--with-stdout" "--with-avahi"
    "--with-ssl=openssl" "--with-soxr" "--with-airplay-2"
    "--without-configfiles"
    "--sysconfdir=/etc"
  ];

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Airtunes server and emulator with multi-room capabilities";
    license = licenses.mit;
    maintainers =  with maintainers; [ lnl7 ];
    platforms = platforms.unix;
  };
}
