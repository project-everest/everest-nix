{ z3
, fstar
, doCheck ? false
, enableParallelBuilding ? true
, ocamlPackages
, stdenv
, symlinks
, which
, src
}:

stdenv.mkDerivation {
  name = "karamel";

  inherit src;

  buildInputs = [
    z3
    which
    symlinks
  ] ++ (with ocamlPackages; [
    ocaml
    ocamlbuild
    findlib
    batteries
    stdint
    ppx_deriving_yojson
    zarith
    pprint
    menhir
    menhirLib
    sedlex_2
    process
    fix
    wasm
    visitors
    ctypes
  ]);

  FSTAR_HOME = fstar;

  configurePhase = ''
    export KRML_HOME=$(pwd)
  '';

  inherit enableParallelBuilding;
  preBuild = ''
    mkdir -p krmllib/hints
  '';
  postBuild = ''
    symlinks -c $KRML_HOME
  '';

  inherit doCheck;
  checkPhase = ''
    make test -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    cp -r ./. $out
  '';
}