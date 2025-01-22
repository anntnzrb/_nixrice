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

    preliminaryMessage.disable = mkOptBool';
  };

  config.home = {
    sessionVariables = {
      NIX_SHELL_PRESERVE_PROMPT = "1";
    } // (lib.optionals (cfg.sessionVariables != null) cfg.sessionVariables);

    # disable "Last Login..." preliminary message
    file.".hushlogin" = lib.mkIf cfg.preliminaryMessage.disable { text = ""; };

    packages = with pkgs; [
      bat
      du-dust
      eza
      fd
      (ripgrep.override { withPCRE2 = true; })
    ];
  };
}
