{ everest-nix }:

let
  system = builtins.currentSystem;
  hydra-helpers = import (everest-nix + "/hydra-helpers/default.nix");
  pkgs = import hydra-helpers.inputs.nixpkgs { inherit system; };
in
with hydra-helpers.lib.${system};

{
  jobsets = pkgs.writeText "spec.json" (builtins.toJSON {
    master = makeJob 1000 "everest master" "github:project-everest/everest-nix?dir=projects";
  });
}
