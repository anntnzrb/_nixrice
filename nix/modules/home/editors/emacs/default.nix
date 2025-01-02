{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.editors.emacs;

  mkEmacsPackage =
    pkg:
    (pkgs.emacsPackagesFor pkg).emacsWithPackages (
      epkgs: with epkgs; [
        treesit-grammars.with-all-grammars

        evil
        vertico
        marginalia
        corfu
        fontaine
        envrc
        ef-themes

        # langs
        gleam-ts-mode
      ]
    );
in
{
  options.${namespace}.editors.emacs = with lib.${namespace}; {
    enable = mkOptBool';

    package = lib.mkOption {
      type = lib.types.package;
      default =
        if pkgs.stdenv.isDarwin then (mkEmacsPackage pkgs.emacs29) else (mkEmacsPackage pkgs.emacs29-pgtk);
      description = "The Emacs package to install.";
    };

  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
