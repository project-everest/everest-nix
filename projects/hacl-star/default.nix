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
, time
}:

stdenv.mkDerivation {
  name = "hacl-star";

  inherit src;

  postPatch = ''
    patchShebangs tools
    patchShebangs dist/configure
    substituteInPlace Makefile --replace "/usr/bin/time" "${time}/bin/time"
    substituteInPlace Makefile --replace "NOSHORTLOG=1" ""
  '';

  nativeBuildInputs = [
    z3
    python3
    which
    mono
    time
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

  dontFixup = true;
}
