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
      shellAliases.aider = "aider --cache-prompts --pretty --stream --no-auto-lint --no-auto-test --no-check-update";
    };
  };
}
