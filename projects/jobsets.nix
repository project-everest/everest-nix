{ everest-nix }:

let
  hydra-helpers = import (everest-nix + "/hydra-helpers/default.nix");
  pkgs = import hydra-helpers.inputs.nixpkgs { system = "x86_64-linux"; };
in
with hydra-helpers.lib;

{
  jobsets = pkgs.writeText "spec.json" (builtins.toJSON {
    name = "branch-master";
    value = makeJob 1000 "Branch master" "github:project-everest/everest-nix?dir=projects";
  });
}
