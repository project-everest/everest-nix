{ stdenv, lib, makeWrapper, which, z3, ocamlPackages, sd,
  sphinx, python39Packages,
  src
}@inputs:
let
  inherit
    (import ./fstar-factory.nix {inherit stdenv lib makeWrapper which z3 ocamlPackages sd;})
    binary-of-fstar check-fstar;
  name = "fstar-${src.shortRev}";
  bin = binary-of-fstar { inherit src name; };
in bin // {
  passthru = {
    tests = check-fstar {
      inherit src;
      name = "${name}-checks";
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
