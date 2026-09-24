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
  programs.rio.settings.bindings.keys = [
    {
      key = "c";
      "with" = "control | shift";
      action = "Copy";
    }
    {
      key = "v";
      "with" = "control | shift";
      action = "Paste";
    }
    {
      key = "=";
      "with" = "control";
      action = "IncreaseFontSize";
    }
    {
      key = "-";
      "with" = "control";
      action = "DecreaseFontSize";
    }
  ];
}
