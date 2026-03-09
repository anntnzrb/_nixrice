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
    ${namespace}.desktop.window-managers.darwin.yashiki._sections.layout = [
      (yashikiLib.cmd "layout-set-default tatami")
      (yashikiLib.cmd "set-outer-gap 8")
      (yashikiLib.cmd "layout-cmd --layout tatami set-inner-gap 8")
      (yashikiLib.cmd "retile")
    ];
  };
}
