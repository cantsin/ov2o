with import <nixpkgs> { };
stdenv.mkDerivation {
  name = "env";
  buildInputs = [ dune_2 ocaml opam gnum4 pkg-config ];
}
# eval $(opam env)
# opam install -y core
# opam install -y icalendar
