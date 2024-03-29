{
  description = "Project Everest";

  inputs = {
    fstar-src    = {url = "github:fstarlang/fstar";           flake = false;};
    karamel-src  = {url = "github:fstarlang/karamel";         flake = false;};
    hacl-src     = {url = "github:project-everest/hacl-star"; flake = false;};

    flake-utils.url = "flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = {
    fstar-src, karamel-src, hacl-src,
      flake-utils, nixpkgs,
      ...
  }: flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
       let pkgs = nixpkgs.legacyPackages.${system};
           inherit (pkgs.lib) mapAttrs mapAttrs' mapAttrsToList nameValuePair filterAttrs foldAttrs;
           everestPackages = pkgs.callPackage ./everestPackages.nix { inherit fstar-src karamel-src hacl-src; };
       in rec {
         packages = { inherit (everestPackages) z3 fstar karamel vale mlcrypto hacl; };
         checks = filterAttrs (_: v: !(isNull v)) (mapAttrs (k: p: (p.passthru or {}).tests or null) packages);
         hydraJobs = foldAttrs (v: _: v) null (mapAttrsToList (k: v: {
           ${k} = v;
         } // mapAttrs' (k': v: nameValuePair "${k}-${k'}" v) (v.passthru or {})) packages) // {
           dependencies = pkgs.stdenv.mkDerivation {
             name = "dependencies";
             phases = ["installPhase"];
             installPhase = ''
               mkdir -p "$out"/nix-support
               echo "doc report $out/dependencies.json" >> $out/nix-support/hydra-build-products
               echo "$REPORT" > $out/dependencies.json
             '';
             REPORT = builtins.toJSON {
               fstar   = fstar-src.rev;
               karamel = karamel-src.rev;
               hacl    = hacl-src.rev;
               nixpkgs = nixpkgs.rev;
             };
           };
         };
       }
     );
}
