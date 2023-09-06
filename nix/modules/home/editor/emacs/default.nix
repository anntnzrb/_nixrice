{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.editor.emacs;
in {
  options.liberion.editor.emacs = {
    enable = mkOptBool' false;
  };

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs29.override {
        withNativeCompilation = true; # emacs28+
        withGTK3 = true;
        withTreeSitter = true; # emacs29+
      };
    };
  };
}
