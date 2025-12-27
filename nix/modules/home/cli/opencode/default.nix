{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;

  cfg = config.${namespace}.cli.opencode;

  opencode-wrapped = pkgs.writeShellApplication {
    name = "opencode";
    text = builtins.readFile ./opencode-wrapped.sh;
  };

in
{
  options.${namespace}.cli.opencode = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ opencode-wrapped ];
  };
}
