{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  cfg = config.liberion.editors.emacs;

  mkEmacsPackage =
    pkg:
    (pkgs.emacsPackagesFor pkg).emacsWithPackages (
      epkgs: with epkgs; [
        pkgs.coreutils-prefixed # provides gls
        vterm
      ]
    );
in
{
  options.liberion.editors.emacs = {
    package = mkOpt' lib.types.package (mkEmacsPackage pkgs.emacs30);
  };

  config = {
    home.packages = [ cfg.package ];

    home.shellAliases = {
      # NOTE: 'disown' is not POSIX
      eee = "${lib.getExe' pkgs.coreutils "nohup"} ${lib.getExe cfg.package} >/tmp/emacs-nohup.out 2>&1 & disown";
    };
  };
}
