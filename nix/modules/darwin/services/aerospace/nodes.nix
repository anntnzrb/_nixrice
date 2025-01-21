{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.aerospace;

  mkDirectionalBindings =
    command: modifier: keyMap:
    lib.listToAttrs (
      lib.mapAttrsToList (key: dir: {
        name = "${modifier}-${key}";
        value = "${command} ${dir}";
      }) keyMap
    );

  vimBindings = {
    h = "left";
    j = "down";
    k = "up";
    l = "right";
  };
in
{
  config.services.aerospace.settings = {
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
}
