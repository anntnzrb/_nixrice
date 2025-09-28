{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;

  cfg = config.${namespace}.cli.gemini;
in
{
  options.${namespace}.cli.gemini = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.gemini = "bunx --bun @google/gemini-cli@latest";
  };
}
