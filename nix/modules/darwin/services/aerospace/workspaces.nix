{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt';
  inherit (lib) range;
  inherit (lib.types)
    listOf
    int
    ;

  cfg = config.${namespace}.services.aerospace;

  /**
    Generate workspace keybindings for a command.

    # Example

    ```nix
    mkWorkspaceBindings "workspace" "m-ctrl"
    =>
    { "m-ctrl-0" = "workspace 0"; "m-ctrl-1" = "workspace 1"; ... }
    ```

    # Type

    ```
    mkWorkspaceBindings :: String -> String -> AttrSet
    ```

    # Arguments

    cmd
    : The workspace command to bind (e.g., "workspace" or "move-node-to-workspace")

    prefix
    : The key binding prefix (e.g., modifier key combination)
  */
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
    workspaceRange = mkOpt' (listOf int) (range 0 9);
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
