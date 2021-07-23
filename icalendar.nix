{ pkgs, ... }:
pkgs.stdenv.mkDerivation rec {
  pname = "icalendar";
  version = "v0.1.4";

  src = pkgs.fetchFromGitHub {
    owner = "roburio";
    repo = "icalendar";
    rev = version;
    sha256 = "sha256-J0K5RR6xg2CjHME5/B/X94ZnK0xQ9+Wt1R2rWtuZSCc=";
  };

  buildInputs = with pkgs; [ ocaml dune_2 ];
  propagatedBuildInputs = with pkgs.ocamlPackages; [
    angstrom
    astring
    findlib
    fmt
    gmap
    ppx_deriving
    ppx_jane
    ptime
    re
    rresult
    uri
  ];

  buildPhase = ''
    dune build -p icalendar
  '';

  installPhase = ''
    mkdir -p $out/tmp
    mkdir -p $out/lib/ocaml/${pkgs.ocaml.version}
    dune install --prefix=$out/tmp
    mv $out/tmp/lib $out/lib/ocaml/${pkgs.ocaml.version}/site-lib
  '';

  meta = with pkgs.lib; {
    description =
      "A library to parse and print the iCalendar (.ics) format as specified in RFC5545.";
    downloadPage = "https://github.com/roburio/icalendar";
    license = licenses.isc;
  };
}
