with import <nixpkgs> { };
stdenv.mkDerivation {
  name = "env";
  buildInputs = [ dune_2 ocaml opam gnum4 pkg-config ]
    ++ (with ocamlPackages; [ merlin ocp-indent utop ]);
  MERLIN_SITE_LISP = "${ocamlPackages.merlin}/share/emacs/site-lisp";
  OCP_INDENT_SITE_LISP = "${ocamlPackages.ocp-indent}/share/emacs/site-lisp";
  UTOP_SITE_LISP = "${ocamlPackages.utop}/share/emacs/site-lisp";
  shellHook = ''
    eval $(opam env)
  '';
}
# opam install -y core icalendar
