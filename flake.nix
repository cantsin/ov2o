{
  description = "ov2o: export calendars into org-mode";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.ov2o = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      ocaml = pkgs.ocaml-ng.ocamlPackages_4_10.ocaml;
      opam2nix = import ./opam2nix.nix { };
      selection = opam2nix.build {
        inherit ocaml;
        selection = ./opam-selection.nix;
        src = ./.;
      };
    in selection.ov2o;
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.ov2o;
  };
}
