{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.aerospace;

  mkWorkspaceBindings =
    cmd: prefix:
    lib.listToAttrs (
      map (num: {
        name = "${prefix}-${toString num}";
        value = "${cmd} ${toString num}";
      }) cfg.workspaceRange
    );
in
{
  options.${namespace}.services.aerospace = {
    workspaceRange = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = lib.range 0 9;
      description = "Workspace numbers to generate bindings for";
    };
  };

  config.services.aerospace.settings = lib.mkIf cfg.enable {
    mode.main.binding =
      (mkWorkspaceBindings "workspace" cfg.modifier)
      // (mkWorkspaceBindings "move-node-to-workspace" "${cfg.modifier}-shift")
      // {
        "${cfg.modifier}-tab" = "workspace-back-and-forth";
        "${cfg.modifier}-shift-tab" = "move-workspace-to-monitor --wrap-around next";
      };
  };
}
