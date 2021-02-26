with import <nixpkgs> { };
stdenv.mkDerivation {
  name = "env";
  buildInputs = [ dune_2 ocaml opam gnum4 pkg-config ];
  shellHook = ''
    export UTOP_SITE_LISP=1
    export MERLIN_SITE_LISP=1
    export OCP_INDENT_SITE_LISP=1
  '';
}
# opam install -y merlin ocamlformat core icalendar
# eval $(opam env)
