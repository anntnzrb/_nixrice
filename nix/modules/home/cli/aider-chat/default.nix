{ config
, lib
, pkgs
, namespace
, ...
}:
let
  cfg = config.${namespace}.cli.aider-chat;
in
{
  options.${namespace}.cli.aider-chat = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.aider-chat ];
      shellAliases.aider = "aider --cache-prompts --dark-mode --pretty --stream --no-check-update";
    };
  };
}
