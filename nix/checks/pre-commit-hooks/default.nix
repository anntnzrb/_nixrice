{ inputs
, pkgs
, ...
}:
inputs.pre-commit-hooks.lib.${pkgs.system}.run {
  src = inputs.self;

  hooks = {
    flake-checker.enable = true;
    actionlint.enable = true;

    deadnix = {
      enable = true;
      settings = {
        edit = true;
        noUnderscore = true;
      };
    };

    statix =
      let
        cfg = (pkgs.formats.toml { }).generate "statix.toml" { disabled = disabled-lints; };
        disabled-lints = [ "repeated_keys" ];
      in
      {
        enable = true;
        package = pkgs.writeShellApplication {
          name = "statix";
          runtimeInputs = [ pkgs.statix ];
          text = ''
            shift
            exec statix check --config ${cfg} "$@"
          '';
        };
      };
  };
}
