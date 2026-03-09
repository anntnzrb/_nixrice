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
    ${namespace}.desktop.window-managers.darwin.yashiki._sections.rules =
      yashikiLib.mkRules
        [
          {
            appId = "org.mozilla.firefox";
            actions = [ "tags 1" ];
          }
          {
            appId = "com.apple.Safari";
            actions = [ "tags 1" ];
          }
          {
            appId = "com.mitchellh.ghostty";
            actions = [ "tags 2" ];
          }
          {
            appId = "com.microsoft.VSCode";
            actions = [ "tags 4" ];
          }
          {
            appId = "net.whatsapp.WhatsApp";
            actions = [
              "tags 8"
              "float"
            ];
          }
          {
            appId = "com.openai.chat";
            actions = [
              "tags 8"
              "float"
            ];
          }
          {
            appId = "com.apple.systempreferences";
            actions = [ "float" ];
          }
          {
            appName = "System Settings";
            actions = [ "float" ];
          }
          {
            appName = "System Preferences";
            actions = [ "float" ];
          }
        ];
  };
}
