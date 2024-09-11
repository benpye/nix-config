{
  lib,
  stdenv,
  requireFile,
  gnutar,
  autoPatchelfHook,
  glibc,
  gtk2,
  xorg,
  libgudev,
  makeDesktopItem,
}:
let
  pname = "vuescan";
  version = "9.8.33";
  desktopItem = makeDesktopItem {
    name = "VueScan";
    desktopName = "VueScan";
    genericName = "Scanning Program";
    comment = "Scanning Program";
    icon = "vuescan";
    terminal = false;
    type = "Application";
    startupNotify = true;
    categories = [
      "Graphics"
      "Utility"
    ];
    keywords = [
      "scan"
      "scanner"
    ];
    exec = "vuescan";
  };
in
stdenv.mkDerivation rec {
  name = "${pname}-${version}";

  src = requireFile {
    name = "vuex64-${version}.tgz";
    url = "https://www.hamrick.com/files/vuex6498.tgz";
    sha256 = "29964019c570b50479e305254076ddb50f68d7ff569c741b11af455f77c3978b";
  };

  # Stripping breaks the program
  dontStrip = true;

  nativeBuildInputs = [
    gnutar
    autoPatchelfHook
  ];

  buildInputs = [
    glibc
    gtk2
    xorg.libSM
    libgudev
  ];

  unpackPhase = ''
    tar xfz $src
  '';

  installPhase = ''
    install -m755 -D VueScan/vuescan $out/bin/vuescan

    mkdir -p $out/share/icons/hicolor/scalable/apps/
    cp VueScan/vuescan.svg $out/share/icons/hicolor/scalable/apps/vuescan.svg

    mkdir -p $out/lib/udev/rules.d/
    cp VueScan/vuescan.rul $out/lib/udev/rules.d/60-vuescan.rules

    echo "# Nikon LS-4000" >> $out/lib/udev/rules.d/60-vuescan.rules
    echo "SUBSYSTEM==\"scsi_generic\",ATTRS{vendor}==\"Nikon   \",ATTRS{model}==\"LS-4000 ED      \", MODE=\"0666\"" >> $out/lib/udev/rules.d/60-vuescan.rules

    mkdir -p $out/share/applications/
    ln -s ${desktopItem}/share/applications/* $out/share/applications
  '';
}
