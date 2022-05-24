{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-21.11";
    hydra.url = "github:NixOS/hydra";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, flake-utils, nixpkgs, hydra, agenix, ... }:
    let
      keys = import ./secrets/keys.nix;
      out = flake-utils.lib.eachDefaultSystem (system: 
        let pkgs = nixpkgs.legacyPackages.${system}; in
        rec {
          packages = {
            hydra = hydra.defaultPackage.${system}.overrideAttrs (_: {
              patches = [
                ./hydra-patches/eval-badly-locked-flakes.diff
                ./hydra-patches/gh-webhook.diff
                ./hydra-patches/disable-restrict-eval.diff
                ./hydra-patches/status-override.diff
              ];
              doCheck = false;
            });
          };
        }
      );
    in
      {
        nixosConfigurations.everest-hydra = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = let
            base = {pkgs, config, ...}: {
              system.stateVersion = "21.11";
              networking.useDHCP = false;
              networking.interfaces.ens3.useDHCP = true;
              users.users.root = {
                openssh.authorizedKeys.keys = [
                  keys.lucas-laptop
                  keys.pnm-laptop
                  keys.everest-ci-nginx
                ];
              };
              age.ageBin = "${pkgs.age}/bin/age"; # See https://github.com/ryantm/agenix/pull/81
              age.secrets.github-token-nix-conf = {
                file = ./secrets/github-token-nix-conf.age;
                owner = "hydra";
                mode = "0440";
              };
            
              services.openssh = {
                gatewayPorts = "yes";
                permitRootLogin = "without-password";
                enable = true;
              };
              nix = {
                package = pkgs.nixFlakes;
                
                extraOptions = ''
                  experimental-features = nix-command flakes
                  warn-dirty = false
                '';
                
                gc = {
                  automatic = true;
                  dates = "daily";
                  options = "--delete-older-than 1d";
                };
              };
              
              i18n.defaultLocale = "en_IE.UTF-8";
            };
            hydra = {config, pkgs, ...}: {
              users.users.hydra.packages = [ pkgs.git ];
              age.secrets.github-token-hydra = {
                file = ./secrets/github-token-hydra.age;
                owner = "hydra";
                mode = "0440";
              };
              age.secrets.hydra-users = {
                file = ./secrets/hydra-users.age;
                owner = "hydra";
                mode = "0440";
              };
              age.secrets.hydra-privateKey = {
                file = ./secrets/id_ed25519.age;
                owner = "hydra";
                mode = "0440";
              };
              services.hydra = {
                enable = true;
                hydraURL = "https://everest-ci.paris.inria.fr";
                notificationSender = "ci@example.org";
                minimumDiskFree = 2;
                minimumDiskFreeEvaluator = 1;
                listenHost = "localhost";
                package = out.packages.${system}.hydra;
                useSubstitutes = true;
                extraConfig = ''
                  evaluator_pure_eval = false
                  <githubstatus>
                    jobs = comparse:.*
                    excludeBuildFromContext = 1
                    useShortContext = 1
                  </githubstatus>
                  <githubstatus>
                    jobs = hacl-star:.*
                    excludeBuildFromContext = 1
                    overrideOwner = project-everest
                    overrideRepo = hacl-star
                    useShortContext = 1
                  </githubstatus>
                  Include ${config.age.secrets.github-token-hydra.path}
                '';
              };
              services.declarative-hydra = {
                enable = true;
                usersFile = config.age.secrets.hydra-users.path;
                hydraNixConf = ''
                  include ${config.age.secrets.github-token-nix-conf.path}
                '';
                sshKeys = {
                  privateKeyFile = config.age.secrets.hydra-privateKey.path;
                  publicKeyFile  = ./secrets/id_ed25519.pub;
                };
                projects =
                  let mkGhProject = { displayname, description, owner, repo, enabled ? 1, visible ? true }: {
                        inherit displayname description enabled visible;
                        declarative.file = "spec.json";
                        declarative.type = "path";
                        declarative.value = "${pkgs.writeTextDir "spec.json" ''
                           { "enabled": 1,
                             "hidden": false,
                             "description": "Everest Jobsets",
                             "nixexprinput": "everest-nix",
                             "nixexprpath": "hydra-helpers/generate-jobsets.nix",
                             "checkinterval": 3600,
                             "schedulingshares": 100,
                             "enableemail": true, 
                             "emailoverride": "",
                             "keepnr": 3,
                             "inputs": {
                               "everest-nix": {
                                 "type": "git",
                                 "value": "https://github.com/project-everest/everest-nix.git master"
                               },
                               "src": {
                                 "type": "git",
                                 "value": "https://github.com/${owner}/${repo}.git master"
                               },
                               "prs": {
                                 "type": "githubpulls",
                                 "value": "${owner} ${repo}"
                               },
                               "refs": {
                                 "type": "github_refs",
                                 "value": "${owner} ${repo} heads - "
                               },
                               "owner": { "type": "string", "value": "${owner}" },
                               "repo": { "type": "string", "value": "${repo}" }
                             }
                           }
                        ''}";
                      }; in {
                        # fstar = mkGhProject {
                        #   displayname = "F*";
                        #   description = "The F* proof-oriented language";
                        #   owner = "fstarlang";
                        #   repo = "fstar";
                        # };
                        krml = mkGhProject {
                          displayname = "KarameL";
                          description = "Extract F* programs to readable C code";
                          owner = "fstarlang";
                          repo = "karamel";
                        };
                        hacl-star = mkGhProject {
                          displayname = "Hacl*";
                          description = "A formally verified library of modern cryptographic algorithms";
                          owner = "project-everest";
                          repo = "hacl-star";
                        };
                        everest = mkGhProject {
                          displayname = "Everest";
                          description = "Efficient, verified components for the HTTPS ecosystem";
                          owner = "project-everest";
                          repo = "everest-nix";
                        };
                      };
              };
            };
          in [ ./hardware.nix ./modules/declarative-hydra.nix base agenix.nixosModule hydra ];
        };
      };
}


