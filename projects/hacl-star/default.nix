{ z3
, fstar
, mlcrypto
, karamel
, vale
, enableParallelBuilding ? true
, mono
, ocamlPackages
, python3
, stdenv
, which
, src
}:

stdenv.mkDerivation {
  name = "hacl-star";

  inherit src;

  postPatch = ''
    patchShebangs tools
    patchShebangs dist/configure
  '';

  nativeBuildInputs = [
    z3
    python3
    which
    mono
  ] ++ (with ocamlPackages; [
    ocaml
    findlib
    batteries
    pprint
    stdint
    yojson
    zarith
    ppxlib
    ppx_deriving
    ppx_deriving_yojson
    ctypes
  ]);

  MLCRYPTO_HOME = mlcrypto;
  VALE_HOME     = vale;
  FSTAR_HOME    = fstar;
  KRML_HOME     = karamel;

  NOSHORTLOG = "1";

  configurePhase = ''
    export HACL_HOME=$(pwd)
  '';

  inherit enableParallelBuilding;

  #preBuild = ''
  #  rm -rf dist/*/{Makefile.basic,package.json}
  #'';

  buildTargets = [ "ci" ];

  installPhase = ''
    cp -r ./. $out
  '';
}
