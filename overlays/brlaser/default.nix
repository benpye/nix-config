self: super: {
  brlaser = super.brlaser.overrideAttrs (oldAttrs: rec {
    name = "brlaser";
    version = "9d7ddda8383bfc4d205b5e1b49de2b8bcd9137f1";
    patches = [ ./lines.patch ];
    src = super.fetchFromGitHub {
      owner = "pdewacht";
      repo = "brlaser";
      rev = "9d7ddda8383bfc4d205b5e1b49de2b8bcd9137f1";
      sha256 = "1drh0nk7amn9a8wykki4l9maqa4vy7vwminypfy1712alwj31nd4";
    };
  });
}
