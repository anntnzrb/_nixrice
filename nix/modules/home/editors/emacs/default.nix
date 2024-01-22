{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.editors.emacs;
in
{
  options.liberion.editors.emacs = {
    enable = lib.mkEnableOption "emacs";

    pgtk = lib.mkEnableOption "emacs with pgtk?";
  };

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;

      package = pkgs.emacs29.override {
        withGTK3 = true;
        withGTK2 = false;
        withPgtk = cfg.pgtk;
        withNativeCompilation = true; # emacs28+
        withTreeSitter = true; # emacs29+
      };
    };

    home.packages = with pkgs; [
      emacsPackages.vterm

      # extras
      mlocate
      (ripgrep.override { withPCRE2 = true; })
      fd
      nodejs # for LSPs

      # lookup
      sqlite
      wordnet
    ];
  };
}
