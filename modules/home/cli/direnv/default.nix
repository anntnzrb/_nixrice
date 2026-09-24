{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  exe = lib.getExe config.programs.direnv.package;

  cfg = config.${namespace}.cli.direnv;
in
{
  options.${namespace}.cli.direnv = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      inherit (cfg) enable;
      silent = true;
      nix-direnv = on;
    };

    home.shellAliases.dirrr = "${exe} allow && ${exe} reload";
  };
}
