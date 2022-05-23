# Hydra Utils

This repository contains Nix helpers for the Hydra-based Everest CI.

`lib/default.nix` exposes `makeGitHubJobsets` which produces `spec.json` declarative jobsets files.
The repository of each project on the CI should include a `.hydra/default.nix` that consumes `makeGitHubJobsets`.

`flake.nix` exposes a patched version of Hydra. `hydra-patches` contains two patches:
 - `gh-webhook.diff`, the PR https://github.com/NixOS/hydra/pull/1207 that adds support for some webhooks;
 - `eval-badly-locked-flakes.diff`, that allow Hydra for building flakes whose lockfile requires an update.

