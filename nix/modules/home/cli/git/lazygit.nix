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
      inherit (cfg.lazygit) enable;
      settings = {
        gui.showCommandLog = false;
      }
      // lib.optionalAttrs cfg.diff.difftastic.enable {
        git.paging.externalDiffCommand = "difft --color=always --display=inline";
      };
    };

    home.shellAliases = mkIf cfg.lazygit.enable {
      gg = "${lib.getExe config.programs.lazygit.package}";
    };
  };
}
