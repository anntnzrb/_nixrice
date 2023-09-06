{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.editor.emacs;

  emacsPackages = epkgs:
    with epkgs; [
      nix-mode
      evil
    ];
in {
  options.liberion.editor.emacs = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs29.override {
        withNativeCompilation = true; # emacs28+
        withGTK3 = true;
        withTreeSitter = true; # emacs29+
      };
      extraPackages = emacsPackages;
    };
  };
}
