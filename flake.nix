{
  description = "ov2o: export calendars into org-mode";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05"; };

  outputs = { self, nixpkgs }: {
    defaultPackage.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      ocamlIcalendar = import ./icalendar.nix { inherit pkgs; };
    in pkgs.stdenv.mkDerivation {
      name = "ov2o";
      src = self;

      buildInputs = with pkgs.ocamlPackages; [
        pkgs.dune_2
        pkgs.ocaml
        pkgs.ocamlformat
        ocp-indent
        ocaml-lsp
        core
        findlib
        ocamlIcalendar
        ppx_deriving
        ppx_jane
      ];

      buildPhase = ''
        dune build ov2o.exe
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp _build/default/ov2o.exe $out/bin/ov2o
      '';
    };
  };
}
