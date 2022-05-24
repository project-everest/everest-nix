{    fstar-src ? throw "Missing `fstar-src`",
   karamel-src ? throw "Missing `karamel-src`",
      hacl-src ? throw "Missing `hacl-src`",
        # z3-src ? null,
  # mlcrypto-src ? throw "Missing `mlcrypto-src`",
      # vale-src ? null
}:
final: prev: {
  fstar    = final.callPackage ./fstar       { src =    fstar-src; };
  karamel  = final.callPackage ./karamel     { src =  karamel-src; };
  hacl     = final.callPackage ./hacl-star   { src =     hacl-src; };
  z3       = final.callPackage ./z3          { z3  =      prev.z3;
                                               /*src =       z3-src;*/ };
  mlcrypto = final.callPackage ./mlcrypto    { /*src = mlcrypto-src; */ };
  vale     = final.callPackage ./vale        { /*src =     vale-src;*/ };
}
