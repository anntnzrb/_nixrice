{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.shells;
in
{
  imports = [
    ./aliases.nix
  ];

  options.${namespace}.shells = with lib.${namespace}; {
    aliases.defaults.enable = mkOptBool';
    sessionVariables = with lib.types; mkOpt' (attrsOf str) { };
  };

  config.home = {
    sessionVariables = {
      NIX_SHELL_PRESERVE_PROMPT = "1";
    } // (lib.optionals (cfg.sessionVariables != null) cfg.sessionVariables);

    packages = with pkgs; [
      bat
      du-dust
      eza
      fd
      (ripgrep.override { withPCRE2 = true; })
    ];
  };
}
