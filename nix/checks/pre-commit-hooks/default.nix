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
inputs.pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
  src = inputs.self;

  hooks = {
    # nix
    flake-checker = on // {
      args = [
        "--check-outdated"
        "--check-owner"
        "--check-supported"
      ];
    };

    nixfmt = on // {
      args = [
        "--strict"
        "--verify"
      ];
      settings.width = 80;
    };

    deadnix = on // {
      args = [ "--warn-used-underscore" ];
      settings.edit = true;
    };

    statix = on;

    shfmt = on // {
      settings = {
        language-dialect = "posix";
        indent = 4;
        binary-next-line = true;
        case-indent = true;
      };
    };

    shellcheck = on // {
      args = [
        "--enable=all"
        "-a"
        "-x"
        "-P"
        "SCRIPTDIR"
      ];
    };

    # GH actions
    actionlint = on;
  };
}
