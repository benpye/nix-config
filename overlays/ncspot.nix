self: super:
{
  ncspot = super.ncspot.overrideAttrs (oldAttrs:
  let
    features = [ "termion_backend" "rodio_backend" "notify" "cover" ]
      ++ super.lib.optional super.stdenv.isLinux  "mpris";
  in
  {
    cargoBuildFlags = [ "--no-default-features" "--features" "${super.lib.concatStringsSep "," features}" ];
    buildInputs = [ super.openssl ]
      ++ super.lib.optional super.stdenv.isDarwin super.libiconv
      ++ super.lib.optional super.stdenv.isLinux  super.alsa-lib
      ++ super.lib.optional super.stdenv.isLinux  super.dbus;
  });
}
