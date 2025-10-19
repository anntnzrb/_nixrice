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
    window = {
      opacity = 0.8;
      blur = true;
      decorations = "Buttonless";
    };

    renderer = {
      performance = "high";
      backend = "automatic";
      disable-unfocused-render = true; # TODO: test
      level = 1; # fonts/ligatures/emojis
    };

    scroll = {
      multiplier = 3.0;
      divider = 1.0;
    };

    navigation = {
      mode = "Plain";
    };
  };
}
