{
  inputs = {
    flake-utils.url = github:numtide/flake-utils;
    nixpkgs.url     = github:NixOS/nixpkgs;
    hydra.url       = github:NixOS/hydra;
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };
  
  outputs = { flake-utils, nixpkgs, hydra, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      lib = import ./lib.nix { pkgs = nixpkgs.legacyPackages.${system}; };
    });
}
