{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  exe = lib.getExe config.programs.direnv.package;

  cfg = config.${namespace}.cli.direnv;
in
{
  options.${namespace}.cli.direnv = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };

    home.shellAliases.dirrr = "${exe} allow && ${exe} reload";
  };
}
