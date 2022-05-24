# Project Everest

This repository contains Nix code for Project Everest and configuration for the Hydra based [CI](https://everest-ci.paris.inria.fr)

It features three flakes:

-`projects/` contains build recipes and hydra jobs definitions for the different parts of the project.

-`hydra-helpers/` contains Nix helpers, notably `hydra-helpers/lib.nix` exposes `makeGitHubJobsets` which produces `spec.json` declarative jobsets files.

-`server-configuration/` contains the server configuration for the machine running Hydra. We use a patched version of Hydra. `server-configuration/hydra-patches` contains two patches:
 - `gh-webhook.diff`, the PR https://github.com/NixOS/hydra/pull/1207 that adds support for some webhooks;
 - `eval-badly-locked-flakes.diff`, that allow Hydra for building flakes whose lockfile requires an update.

