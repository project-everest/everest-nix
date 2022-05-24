{ everest-nix }:

with (import (everest-nix + "/hydra-helpers/default.nix")).lib;

{
  jobsets = pkgs.writeText "spec.json" (builtins.toJSON {
    name = "branch-master";
    value = makeJob 1000 "Branch master" "github:project-everest/everest-nix?dir=projects";
  });
}
