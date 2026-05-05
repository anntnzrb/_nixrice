{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';
  cfg = config.${namespace}.editors.emacs;

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
  options.${namespace}.editors.emacs = {
    enable = mkOptDisabled';

    package = mkOpt' lib.types.package (mkEmacsPackage pkgs.emacs30);
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    home.shellAliases = {
      # NOTE: 'disown' is not POSIX
      eee = "${lib.getExe' pkgs.coreutils "nohup"} ${lib.getExe cfg.package} >/tmp/emacs-nohup.out 2>&1 & disown";
    };
  };
}
