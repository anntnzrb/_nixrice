{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.window-managers.darwin.yashiki;
  yashikiLib = import ./lib.nix { inherit lib; };
in
{
  config = lib.mkIf cfg.enable {
    ${namespace}.desktop.window-managers.darwin.yashiki._sections.bindings =
      (yashikiLib.mkTagBindings yashikiLib.tagSpecs)
      ++ (yashikiLib.mkBindings [
        {
          key = "alt-h";
          action = "window-focus left";
        }
        {
          key = "alt-j";
          action = "window-focus down";
        }
        {
          key = "alt-k";
          action = "window-focus up";
        }
        {
          key = "alt-l";
          action = "window-focus right";
        }

        {
          key = "alt-shift-h";
          action = "window-swap left";
        }
        {
          key = "alt-shift-j";
          action = "window-swap down";
        }
        {
          key = "alt-shift-k";
          action = "window-swap up";
        }
        {
          key = "alt-shift-l";
          action = "window-swap right";
        }

        {
          key = "alt-shift-f";
          action = "window-toggle-float";
        }
        {
          key = "alt-shift-space";
          action = "window-toggle-float";
        }

        {
          key = "alt-shift-t";
          action = "layout-set tatami";
        }
        {
          key = "alt-shift-b";
          action = "layout-set byobu";
        }
        {
          key = "alt-shift-r";
          action = ''exec "sh -c '(sleep 1; open -a /Applications/Yashiki.app) & yashiki quit'"'';
        }
      ]);
  };
}
