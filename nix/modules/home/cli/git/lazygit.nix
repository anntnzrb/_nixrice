{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.cli.git;
in
{
  config = mkIf cfg.enable {
    programs.lazygit = mkIf cfg.lazygit.enable {
      enable = true;
      settings.gui.showCommandLog = false;
    };

    home.shellAliases = mkIf cfg.lazygit.enable {
      gg = "${lib.getExe config.programs.lazygit.package}";
    };
  };
}
