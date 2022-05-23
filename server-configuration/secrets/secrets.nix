let inherit (import ./keys.nix) hydra-server lucas-laptop pnm-laptop; in
{
  "github-token-hydra.age".publicKeys = [hydra-server lucas-laptop pnm-laptop];
  "github-token-nix-conf.age".publicKeys = [hydra-server lucas-laptop pnm-laptop];
  "hydra-users.age".publicKeys = [hydra-server lucas-laptop pnm-laptop];
  "id_ed25519.age".publicKeys = [hydra-server lucas-laptop pnm-laptop];
}
