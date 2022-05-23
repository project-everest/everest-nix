{    fstar-src ? throw "Missing `fstar-src`",
   karamel-src ? throw "Missing `karamel-src`",
      hacl-src ? throw "Missing `hacl-src`",
        # z3-src ? null,
  # mlcrypto-src ? throw "Missing `mlcrypto-src`",
      # vale-src ? null
}:
final: prev: {
  fstar    = final.callPackage ./fstar/fstar.nix { src =    fstar-src; };
  karamel  = final.callPackage ./karamel.nix     { src =  karamel-src; };
  hacl     = final.callPackage ./hacl.nix        { src =     hacl-src; };
  z3       = final.callPackage ./fstar/z3.nix    { z3  =     prev.z3;
                                                 /*src =       z3-src;*/ };
  mlcrypto = final.callPackage ./mlcrypto.nix    { /* src = mlcrypto-src; */ };
  vale     = final.callPackage ./vale.nix        {/*src =     vale-src;*/ };
}
