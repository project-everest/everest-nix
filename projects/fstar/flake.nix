{
  description = "FStar";

  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "flake-utils";
    fstar-src = {
      flake = false;
      url = "github:fstarlang/fstar";
    };
  };

  outputs = { self, nixpkgs, flake-utils, fstar-src }:
    let
      systems = [ "x86_64-linux" ];
    in flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        z3 = pkgs.callPackage ./z3.nix {};
        fstar-factory = pkgs.callPackage ./default.nix {
          inherit z3;
          ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_12;
        };
        fstar = fstar-factory.binary-of-fstar {
          src = fstar-src;
          name = "fstar-master";
        };
        fstar-checks = fstar-factory.check-fstar {
          src = fstar-src;
          name = "fstar-master-checks";
          existing-fstar = fstar;
        };
      in {
        packages = {
          inherit z3 fstar;
        };
        checks = {
          inherit fstar-checks;
        };
        defaultPackage = fstar;
        hydraJobs = {
          inherit fstar-checks;
          fstar-build = fstar;
          fstar-doc = pkgs.stdenv.mkDerivation {
            name = "fstar-book";
            src = ./doc/book;
            buildInputs = with pkgs; [ sphinx python39Packages.sphinx_rtd_theme ];
            installPhase = ''
            mkdir -p "$out"/nix-support
            echo "doc manual $out/book" >> $out/nix-support/hydra-build-products
            mv _build/html $out/book
          '';
          };
        };
      }
    );
}
