{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.editor.neovim;
in {
  options.liberion.editor.neovim = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
    };
  };
}
