{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.aider-chat;
in
{
  options.liberion.cli.aider-chat = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.aider-chat ];
      shellAliases.aider = "${lib.getExe pkgs.aider-chat} --cache-prompts --pretty --stream";
    };
  };
}
