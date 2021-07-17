self: super:
{
  caddyExtra = super.callPackage ./caddy.nix {
    plugins = [
      { url = "github.com/caddy-dns/cloudflare"; rev = "964e47d3890e63d20c44642bc4090a1705261928"; }
    ];
    vendorSha256 = "1hdpfq072zfs7mvb0g60rsx7wm5jl12pyzryx8x4znww1m8b3flx";
  };

  matrix-ircd = super.callPackage ./matrix-ircd.nix {};
}
