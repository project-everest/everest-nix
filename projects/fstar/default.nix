{ stdenv, lib, makeWrapper, which, ocamlPackages, sd, sphinx, python39Packages
, z3, src }@inputs:
let
  inherit (import ./fstar-factory.nix {
    inherit stdenv lib makeWrapper which ocamlPackages sd;
    z3 = z3;
  })
    binary-of-fstar check-fstar;
  name = "fstar-${src.shortRev}";
  rev = src.rev;
  bin = binary-of-fstar { inherit src name rev; };
in bin // {
  passthru = {
    tests = check-fstar {
      inherit src;
      name = "${name}-checks";
      rev = src.rev;
      existing-fstar = bin;
    };
    doc = stdenv.mkDerivation {
      name = "${name}-book";
      src = src + "/doc/book";
      buildInputs = [ sphinx python39Packages.sphinx_rtd_theme ];
      installPhase = ''
        mkdir -p "$out"/nix-support
        echo "doc manual $out/book" >> $out/nix-support/hydra-build-products
        mv _build/html $out/book
        echo "test3" > $out/book/test-wit
      '';
    };
  };
}
