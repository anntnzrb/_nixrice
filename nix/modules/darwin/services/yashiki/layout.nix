{
  lib,
  config,
  namespace,
  yashikiLib,
  ...
}:
let
  cfg = config.${namespace}.desktop.window-managers.darwin.yashiki;
in
{
  config = lib.mkIf cfg.enable {
    ${namespace}.desktop.window-managers.darwin.yashiki._sections.layout = [
      (yashikiLib.cmd "layout-set-default tatami")
      (yashikiLib.cmd "set-outer-gap 8")
      (yashikiLib.cmd "layout-cmd --layout tatami set-inner-gap 8")
      (yashikiLib.cmd "retile")
    ];
  };
}
