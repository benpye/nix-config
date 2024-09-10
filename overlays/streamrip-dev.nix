self: super:
{
  streamrip-dev = super.streamrip.overrideAttrs (oldAttrs: rec {
    version = "4c98dbd44ece7e0d1d9d199e4d743793690e872b";

    src = super.fetchFromGitHub {
      owner = "nathom";
      repo = "streamrip";
      rev = "${version}";
      hash = "sha256-A7oJ1H4WaCsVyYDYWFgM4CdYJlGYwUL0bLcGy3TTQ6U=";
    };
  });
}
