{config, pkgs, lib, ...}:
let
  hydra-jobset-common = {
    enabled = lib.mkOption
      { description = "Wether the jobset is enabled";
        type = types.int;  default = 1;     };
    hidden = lib.mkOption
      { description = "Wether the jobset is hidden";
        type = types.bool; default = false; };
    description = lib.mkOption
      { description = "Description of the jobset";
        type = types.str; };
    checkinterval = lib.mkOption
      { description = "The jobset will be evaluated at `t=0, checkinterval, checkinterval*2, ...`. `0` disables polling.";
        type = types.int;  default = 0; };
    schedulingshares = lib.mkOption
      { description = "TODO";
        type = types.int;  default = 100; };
    enableemail = lib.mkOption
      { description = "TODO";
        type = types.bool; default = false; };
    enable_dynamic_run_command = lib.mkOption
      { description = "TODO";
        type = types.bool; default = false; };
    emailoverride = lib.mkOption
      { description = "TODO";
        type = types.str;  default = ""; };
    keepnr = lib.mkOption
      { description = "The number of derivations to keep.";
        type = types.int;  default = 3; };
  };
  hydra-declarative-input = types.submodule {
    options = {
      type = lib.mkOption
        { description = "The type of the declarative input (i.e. `git`, `string`, `githubpulls`...)";
          type = types.str; };
      value = lib.mkOption
        { description = "The value of the declarative input (i.e. a git URI, a string...)";
          type = types.str; };
      emailresponsible = lib.mkOption
        { description = "TODO";
          type = types.bool; default = false; };
    };
  };
  types = lib.types // {
    hydra-project =
      types.submodule ({name, ...}: {
        options = {
          displayname = lib.mkOption
            { type = types.str; default = name; };
          description = lib.mkOption
            { type = types.str; default = "No description"; };
          enabled = lib.mkOption
            { type = types.int; default = 1; };
          visible = lib.mkOption
            { type = types.bool; default = true; };
          declarative = lib.mkOption
            { description = "Enable Hydra's declarative jobsets, via JSON files.";
              type = types.nullOr (types.submodule {
                options = {
                  file = lib.mkOption
                    { type = types.str; description = "The JSON file describing the project"; };
                  type = lib.mkOption { type = types.str; };
                  value = lib.mkOption { type = types.str; };
                };
              }); };
        };
      });
    hydra-jobset =
      types.either
        (types.submodule {
          options = hydra-jobset-common // {
            nixexprinput = lib.mkOption
              { description = "Which input will be used for evaluating the Nix expression of the jobset";
                type = types.str; };
            nixexprpath = lib.mkOption
              { description = "Where is the Nix expression for creating the jobset (i.e. `nixexprinput/nixexprpath`)";
                type = types.str; };
            inputs = lib.mkOption
              { description = "The declarative inputs of the jobset";
                type = types.attrsOf hydra-declarative-input;
              };
          };
        })
        (types.submodule {
          options = hydra-jobset-common // {
            flake = lib.mkOption
              { description = "The flake URI of the jobset";
                type = types.str; };
          };
        });
  };
  cfg = config.services.declarative-hydra;
in
{
  options.services.declarative-hydra = {
    enable = lib.mkEnableOption "Declarative hydra";
    usersFile = lib.mkOption {
      type = types.path;
      description = "Path to a file where each file is of the form [user:hash:role]";
    };
    projects = lib.mkOption {
      description = "Projects respecting Hydra's format (see Hydra manual)";
      type = types.attrsOf types.hydra-project;
    };
    
    hydraNixConf = lib.mkOption {
      type = types.str;
    };
    sshKeys = lib.mkOption {
      default = null;
      description = "SSH keys for the Hydra user. This is useful for eg private repos.";
      type = types.nullOr (types.submodule {
        options = {
          publicKeyFile = lib.mkOption {
            description = "Path to the ed25519 public key";
            type = types.oneOf [types.str types.path];
          };
          privateKeyFile = lib.mkOption {
            description = "Path to the ed25519 private key";
            type = types.oneOf [types.str types.path];
            default = null;
          };
        };
      });
    };
  };
  config = {
    systemd.services.declarative-hydra = lib.mkIf cfg.enable {
      after = [ "hydra-server.service" ];
      wantedBy = [ "multi-user.target" ];
      enable = true;
      description = "Initialize Hydra's with base users and projects";
      path = lib.mkForce (
        config.systemd.services.hydra-evaluator.path
        ++ [ pkgs.curl pkgs.jq ]
      );
      environment = lib.filterAttrs (k: _: k != "PATH") config.systemd.services.hydra-evaluator.environment;
      serviceConfig = {
        User = "hydra";
        ExecStart = "${(pkgs.writeScript ''declarative-hydra'' ''
                       #!${pkgs.bash}/bin/bash
                       mkdir -p $HOME/.config/nix
                       echo "$hydraNixConf" > $HOME/.config/nix/nix.conf
                       
                       mkdir -p $HOME/.ssh/
                       cat '${cfg.sshKeys.privateKeyFile}' > $HOME/.ssh/id_ed25519
                       cat '${cfg.sshKeys.publicKeyFile}'  > $HOME/.ssh/id_ed25519.pub
                       chmod 600 $HOME/.ssh/id_ed25519
                       chmod 600 $HOME/.ssh/id_ed25519.pub

                       sleep 4
                       cat "${cfg.usersFile}" <(echo) | while IFS= read -r line; do
                         [[ "$line" =~ ^[[:space:]]*$ ]] && continue
                         IFS=':' read user hash role <<< "$line"
                         echo "Creating user [$user]"
                         hydra-create-user "$user" --password-hash "$hash" --role "$role"
                       done
                       
                       baseUrl="http://localhost:${toString config.services.hydra.port}"
                       cookie=$(mktemp)
                       getRandom () { LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c$1; }
                       prepareUser () {
                         pwd=$(getRandom 40)
                         hydra-create-user "custom-init-script" --password "$pwd" --role admin
                       }
                       login () {
                           curl -b "$cookie" -c "$cookie" \
                                -X POST -H "Origin: $baseUrl" -H "Referer: $baseUrl" \
                                -H 'Content-Type: application/json' \
                                "$baseUrl/login" -d "{\"username\": \"custom-init-script\", \"password\": \"$pwd\"}"
                       }
                       createProject () {
                           curl -b "$cookie" -c "$cookie" \
                                -s -X PUT -H 'Content-Type: application/json' \
                                "$baseUrl/project/$1" \
                                -d "$2"
                       }
                       prepareUser
                       login
                       ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (id: def:
                         "createProject '${id}' '${builtins.toJSON (def // {name = id;})}'"
                       ) cfg.projects)}
                       rm "$cookie"
                  '').overrideAttrs (_: { inherit (cfg) hydraNixConf; })}";
      };
    };
  };
}
