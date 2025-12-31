{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.aerospace;

  /**
    Create directional key bindings for Aerospace window manager.

    # Example

    ```nix
    mkDirectionalBindings "focus" "M-a" vimBindings
    =>
    { "M-a-h" = "focus left"; "M-a-j" = "focus down"; "M-a-k" = "focus up"; "M-a-l" = "focus right"; }
    ```

    # Type

    ```
    mkDirectionalBindings :: String -> String -> AttrSet -> AttrSet
    ```

    # Arguments

    command
    : The command to execute (e.g., "focus", "move")

    modifier
    : The key modifier prefix (e.g., "M-a")

    keyMap
    : Attribute set mapping keys to directions (e.g., vimBindings)
  */
  mkDirectionalBindings =
    command: modifier: keyMap:
    lib.listToAttrs (
      lib.mapAttrsToList (key: dir: {
        name = "${modifier}-${key}";
        value = "${command} ${dir}";
      }) keyMap
    );

  /**
    Vim-style direction key bindings for Aerospace.

    # Example

    ```nix
    vimBindings
    =>
    { h = "left"; j = "down"; k = "up"; l = "right"; }
    ```

    # Type

    ```
    vimBindings :: AttrSet
    ```
  */
  vimBindings = {
    h = "left";
    j = "down";
    k = "up";
    l = "right";
  };
in
{
  config = lib.mkIf cfg.enable {
    services.aerospace.settings = {
      accordion-padding = 0;
      gaps = {
        inner = {
          horizontal = 8;
          vertical = 8;
        };
        outer = {
          top = 4;
          right = 4;
          bottom = 4;
          left = 4;
        };
      };

      mode.main.binding =
        (mkDirectionalBindings "focus" cfg.modifier vimBindings)
        // (mkDirectionalBindings "move" "${cfg.modifier}-shift" vimBindings)
        // {
          "${cfg.modifier}-shift-f" = "fullscreen";
        };
    };
  };
}
