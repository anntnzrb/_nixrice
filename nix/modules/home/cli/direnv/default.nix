{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  exe = lib.getExe config.programs.direnv.package;

  cfg = config.${namespace}.cli.direnv;
in
{
  options.${namespace}.cli.direnv = {
    enable = mkOptBool';
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
