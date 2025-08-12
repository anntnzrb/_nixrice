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

  cfg = config.${namespace}.cli.opencode;
in
{
  options.${namespace}.cli.opencode = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.opencode = "nix --accept-flake-config run github:numtide/nix-ai-tools#opencode --";
  };
}
