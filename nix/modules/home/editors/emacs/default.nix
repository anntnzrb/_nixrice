{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.editors.emacs;

  packages = {
    dependencies = with pkgs; [
      fd
      (ripgrep.override { withPCRE2 = true; })
    ];

    emacsPkgs = with pkgs.emacsPackages; [
      vterm
    ];

    extras = with pkgs; [
      nodejs # for lsp copilot auth

      # lookup
      sqlite
      wordnet
    ];

    dicts = with pkgs; [
      (aspellWithDicts (dicts: with dicts;
      [
        # english
        en
        en-computers
        en-science

        es # spanish/español
        de # german/deutsch
      ]))
    ];
  };
in
{
  options.liberion.editors.emacs = with lib.liberion; {
    enable = mkOptBool';

    pgtk = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;

      package = pkgs.emacs29.override {
        withGTK3 = true;
        withGTK2 = false;
        withPgtk = cfg.pgtk && !pkgs.stdenv.isDarwin;
        withNativeCompilation = true; # emacs28+
        withTreeSitter = true; # emacs29+
        withSQLite3 = true;
      };
    };

    home = {
      sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];
      packages = with packages; emacsPkgs ++ dependencies ++ extras ++ dicts;
    };
  };
}
