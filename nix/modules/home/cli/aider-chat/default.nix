{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.cli.aider-chat;
in
{
  options.${namespace}.cli.aider-chat = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.aider-chat ];
      shellAliases.aider = "aider --cache-prompts --pretty --stream";
    };
  };
}
