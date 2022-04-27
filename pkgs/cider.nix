{ stdenv, lib, pkgs, fetchurl }:

stdenv.mkDerivation rec {
  name = "cider";
  version = "1.4.1661";

  src = fetchurl {
    url = "https://output.circle-artifacts.com/output/job/5b3a7567-7111-48ac-82a7-74ef75579747/artifacts/0/~/Cider/dist/artifacts/cider_1.4.0-beta.1661_amd64.deb";
    sha256 = "sha256-O+MJhImwwW373hiIR9Fa901Wb7OwpYwobxAFgOfryzk=";
  };

  nativeBuildInputs = with pkgs; with xorg; [
    alsa-lib
    autoPatchelfHook
    cups
    dpkg
    libdrm
    libuuid
    libXdamage
    libX11
    libXScrnSaver
    libXtst
    libxcb
    libxshmfence
    mesa
    nss
    wrapGAppsHook
  ];

  dontWrapGApps = true;

  libPath = with pkgs; with xorg; lib.makeLibraryPath [
    libcxx
    systemd
    libpulseaudio
    libdrm
    mesa
    stdenv.cc.cc
    alsa-lib
    atk
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libnotify
    libX11
    libXcomposite
    libuuid
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    nspr
    nss
    libxcb
    pango
    libXScrnSaver
    libappindicator-gtk3
    libdbusmenu
  ];

  unpackPhase = "dpkg-deb -x $src .";

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib

    mv usr/share $out/share
    mv opt/Cider $out/lib/Cider

    # Symlink to bin
    mkdir -p $out/bin
    ln -s $out/lib/Cider/cider $out/bin/cider

    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      $out/bin/cider

    wrapProgram $out/bin/cider \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--enable-features=UseOzonePlatform --ozone-platform=wayland}}" \
      --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/" \
      --prefix LD_LIBRARY_PATH : ${libPath}:$out/bin/cider

    # Create required symlinks:
    ln -s libGLESv2.so $out/lib/Cider/libGLESv2.so.2

    runHook postInstall
  '';

  preFixup = ''
    # Fix the desktop link
    substituteInPlace $out/share/applications/cider.desktop \
      --replace /opt/Cider/cider $out/bin/cider
  '';
}
