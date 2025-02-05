{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace})
    mkOpt'
    mkOptBool'
    ;
  inherit (lib.types)
    attrsOf
    str
    ;

  cfg = config.${namespace}.shells;
in
{
  imports = [
    ./aliases.nix
  ];

  options.${namespace}.shells = {
    aliases.defaults.enable = mkOptBool';
    sessionVariables = mkOpt' (attrsOf str) { };
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
