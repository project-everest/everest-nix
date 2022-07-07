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
      echo "0.3.19" > vale/.vale_version
    '';

    nativeBuildInputs = [ z3 fstar python3 which dotnet-runtime time ]
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

    #preBuild = ''
    #  rm -rf dist/*/*
    #'';

    buildFlags = [ "-k" ];

    buildTargets = [ "ci" ];

    installPhase = ''
      cp -r ./. $out
    '';

    dontFixup = true;

    passthru = {
      build-products = stdenv.mkDerivation {
        name = "hacl-build-products";
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out
          cp -r ${hacl}/hints .
          chmod -R +w hints
          cp -r ${hacl}/dist .
          chmod -R +w dist

          for target in c89-compatible election-guard gcc-compatible gcc64-only mitls msvc-compatible portable-gcc-compatible
          do
            sed -i 's/\#\!.*/\#\!\/usr\/bin\/env bash/' dist/$target/configure
          done

          tar -cvf $out/hints.tar hints/
          tar -cvf $out/dist.tar \
            --exclude='*.a' \
            --exclude='*.cmi' \
            --exclude='*.cmx' \
            --exclude='*.cmxa' \
            --exclude='*.d' \
            --exclude='*.exe' \
            --exclude='*.o' \
            --exclude='*.so' \
            dist/*/*
          echo ${src.rev} > $out/rev.txt

          mkdir -p $out/nix-support
          echo "file hints $out/hints.tar" >> $out/nix-support/hydra-build-products
          echo "file dist $out/dist.tar" >> $out/nix-support/hydra-build-products
          echo "file rev $out/rev.txt" >> $out/nix-support/hydra-build-products
        '';
      };
    };

  };

in

hacl
