{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
inputs.pre-commit-hooks.lib.${pkgs.system}.run {
  src = inputs.self;

  hooks = {
    # nix
    flake-checker = on;

    nixfmt-rfc-style = on // {
      settings.width = 80;
    };

    deadnix = on // {
      settings = {
        edit = true;
        noUnderscore = true;
      };
    };

    statix =
      let
        cfg = (pkgs.formats.toml { }).generate "statix.toml" {
          disabled = disabled-lints;
        };
        disabled-lints = [ "repeated_keys" ];
      in
      on
      // {
        package = pkgs.writeShellApplication {
          name = "statix";
          runtimeInputs = [ pkgs.statix ];
          text = ''
            shift
            exec statix check --config ${cfg} "$@"
          '';
        };
      };

    shfmt = on // {
      package = pkgs.writeShellApplication {
        name = "shfmt";
        runtimeInputs = [ pkgs.shfmt ];
        text = ''
          shift
          exec shfmt --posix --write --simplify --indent 4 --binary-next-line --case-indent  "$@"
        '';
      };
    };

    # GH actions
    actionlint = on;
  };
}
