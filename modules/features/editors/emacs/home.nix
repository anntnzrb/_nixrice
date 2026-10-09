{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  cfg = config.liberion.editors.emacs;

  mkEmacsPackage =
    pkg:
    (pkgs.emacsPackagesFor pkg).emacsWithPackages (
      epkgs: with epkgs; [
        pkgs.coreutils-prefixed
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
      eee = "${lib.getExe' pkgs.coreutils "nohup"} ${lib.getExe cfg.package} >/tmp/emacs-nohup.out 2>&1 & disown";
    };
  };
}
