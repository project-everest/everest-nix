{
  inputs = {
    flake-utils.url = github:numtide/flake-utils;
    nixpkgs.url     = github:NixOS/nixpkgs;
    hydra.url       = github:NixOS/hydra;
  };
  
  outputs = { flake-utils, nixpkgs, hydra, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      lib = import ./default.nix { pkgs = nixpkgs.legacyPackages.${system}; };
    });
}
