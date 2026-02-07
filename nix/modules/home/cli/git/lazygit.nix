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
      settings =
        lib.recursiveUpdate
          {
            disableStartupPopups = true;
            gui = {
              mouseEvents = false;
              showCommandLog = false;
            };
            spinner.rate = 100;
            git = {
              autoFetch = true;
              autoRefresh = true;
              fetchAll = false;
            };
            refresher = {
              refreshInterval = 3;
              fetchInterval = 180;
            };
          }
          (
            lib.optionalAttrs cfg.diff.difftastic.enable {
              git.paging.externalDiffCommand = "difft --color=always --display=inline --background dark";
            }
          );
    };

    home.shellAliases = mkIf cfg.lazygit.enable {
      gg = "${lib.getExe config.programs.lazygit.package}";
    };
  };
}
