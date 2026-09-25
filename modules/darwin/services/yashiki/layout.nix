{
  lib,
  config,
  yashikiLib,
  ...
}:
let
  cfg = config.liberion.desktop.window-managers.darwin.yashiki;
in
{
  config = lib.mkIf cfg.enable {
    liberion.desktop.window-managers.darwin.yashiki._sections.layout = [
      (yashikiLib.cmd "layout-set-default tatami")
      (yashikiLib.cmd "set-outer-gap 8")
      (yashikiLib.cmd "layout-cmd --layout tatami set-inner-gap 8")
      (yashikiLib.cmd "retile")
    ];
  };
}
