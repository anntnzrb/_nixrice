{
  lib,
  aerospaceLib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.window-managers.darwin.aerospace;
in
{
  config = lib.mkIf cfg.enable {
    services.aerospace.settings.mode.main.binding =
      (aerospaceLib.mkWorkspaceBindings cfg.workspaceRange "workspace" cfg.modifier)
      // (aerospaceLib.mkWorkspaceBindings cfg.workspaceRange "move-node-to-workspace"
        "${cfg.modifier}-shift"
      )
      // {
        "${cfg.modifier}-tab" = "workspace-back-and-forth";
        "${cfg.modifier}-shift-tab" = "move-workspace-to-monitor --wrap-around next";
      };
  };
}
