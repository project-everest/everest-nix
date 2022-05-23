{ owner, repo, prs, refs, ... }:
(builtins.getFlake "github:project-everest/everest-nix?dir=hydra-helpers").lib.${builtins.currentSystem}.makeGitHubJobsets
  {inherit owner repo;}
  {inherit prs refs;}
