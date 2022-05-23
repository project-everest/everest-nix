{ owner, repo, prs, refs, everest-nix, ... }:
(import (everest-nix + "/hydra-helpers/default.nix")).lib.${builtins.currentSystem}.makeGitHubJobsets
  {inherit owner repo;}
  {inherit prs refs;}
