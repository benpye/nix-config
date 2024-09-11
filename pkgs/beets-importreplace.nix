{
  lib,
  fetchFromGitHub,
  beets,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "beets-importreplace";
  version = "0.2";

  src = fetchFromGitHub {
    repo = "beets-importreplace";
    owner = "edgars-supe";
    rev = "v${version}";
    sha256 = "sha256-PiJ2wYqfAd9XWHIiHO73fOhEIGN2dN+STfC8cQCddd4=";
  };

  nativeCheckInputs = [
    python3Packages.pytestCheckHook
    beets
  ];

  preCheck = ''
    HOME="$(mktemp -d)"
  '';

  meta = with lib; {
    description = "Plugin for beets to perform regex replacements during import ";
    homepage = "https://github.com/edgars-supe/beets-importreplace";
    maintainers = with maintainers; [ benpye ];
    license = licenses.mit;
  };
}
