self: super:
{
  libsForQt5 = super.libsForQt5 // {
    sddm = super.libsForQt5.sddm.overrideAttrs (oldAttrs: rec {
      version = "e67307e4103a8606d57a0c2fd48a378e40fcef06";
      src = super.fetchFromGitHub {
        owner = "sddm";
        repo = "sddm";
        rev = "e67307e4103a8606d57a0c2fd48a378e40fcef06";
        sha256 = "sha256-FfbYQrHndU7rtI8CKK7wtn3pdufBSiXUgefozCja4Do=";
      };
      patches = [];
      buildInputs = super.libsForQt5.sddm.buildInputs ++ [
        super.libsForQt5.layer-shell-qt
        super.libsForQt5.qt5.qtvirtualkeyboard
      ];
    });
  };
}
