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
    services.aerospace.settings = {
      accordion-padding = 0;
      "focus-follows-mouse".enabled = true;
      on-focused-monitor-changed = [ ];

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
        (aerospaceLib.mkDirectionalBindings "focus" cfg.modifier
          aerospaceLib.vimBindings
        )
        // (aerospaceLib.mkDirectionalBindings "move" "${cfg.modifier}-shift"
          aerospaceLib.vimBindings
        )
        // {
          "${cfg.modifier}-shift-f" = "fullscreen";
        };
    };
  };
}
