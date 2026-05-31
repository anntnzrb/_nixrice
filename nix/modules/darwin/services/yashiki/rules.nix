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
    ${namespace}.desktop.window-managers.darwin.yashiki._sections.rules =
      yashikiLib.mkRules
        [
          {
            appName = "*";
            actions = [ "float" ];
          }
          {
            appId = "org.gnu.Emacs";
            actions = [ "no-float" ];
          }
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
