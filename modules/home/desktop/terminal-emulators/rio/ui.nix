{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.terminal-emulators.rio;
in
lib.mkIf cfg.enable {
  programs.rio.settings = {
    hide-cursor-when-typing = false;

    padding-x = 0;
    padding-y = [
      0
      0
    ];

    line-height = 1.0;

    cursor = {
      blinking = true;
      blinking-interval = 400;
    };
  };
}
