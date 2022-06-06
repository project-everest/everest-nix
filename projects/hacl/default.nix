{ enableParallelBuilding ? true, dotnet-runtime, ocamlPackages, python3, stdenv
, which, time, z3, fstar, karamel, vale, mlcrypto, src }:

let

  hacl = stdenv.mkDerivation {
    name = "hacl-star";

    inherit src;

    postPatch = ''
      patchShebangs tools
      patchShebangs dist/configure
      substituteInPlace Makefile --replace "/usr/bin/time" "`which time`"
      substituteInPlace Makefile --replace "NOSHORTLOG=1" ""
    '';

    nativeBuildInputs = [ z3 python3 which dotnet-runtime time ]
      ++ (with ocamlPackages; [
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
    VALE_HOME = vale;
    FSTAR_HOME = fstar;
    KRML_HOME = karamel;

    configurePhase = ''
      export HACL_HOME=$(pwd)
    '';

    inherit enableParallelBuilding;

    preBuild = ''
      rm -rf dist/*/*
    '';

    buildTargets = [ "ci" ];

    installPhase = ''
      cp -r ./. $out
    '';

    dontFixup = true;

    passthru = {
      dist = stdenv.mkDerivation {
        name = "hacl-dist";
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out
          cd ${hacl}
          tar -cvf $out/dist.tar dist/*/*

          mkdir -p $out/nix-support
          echo "file dist $out/dist.tar" >> $out/nix-support/hydra-build-products
        '';
      };
      hints = stdenv.mkDerivation {
        name = "hacl-hints";
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out
          cd ${hacl}
          tar -cvf $out/hints.tar hints/

          mkdir -p $out/nix-support
          echo "file hints $out/hints.tar" >> $out/nix-support/hydra-build-products
        '';
      };
    };

  };

in

hacl
