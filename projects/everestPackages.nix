{ callPackage, ocaml-ng, fstar-src, karamel-src, hacl-src }:

let
  ocamlPackages = ocaml-ng.ocamlPackages_4_12;
  everestPackages = rec {
    mlcrypto = callPackage ./mlcrypto { };
    z3 = callPackage ./z3 { };
    fstar = callPackage ./fstar {
      inherit ocamlPackages z3;
      src = fstar-src;
    };
    karamel = callPackage ./karamel {
      inherit ocamlPackages fstar z3;
      src = karamel-src;
    };
    vale = callPackage ./vale { };
    hacl = callPackage ./hacl {
      inherit ocamlPackages z3 fstar karamel vale mlcrypto;
      src = hacl-src;
    };
  };
in everestPackages
