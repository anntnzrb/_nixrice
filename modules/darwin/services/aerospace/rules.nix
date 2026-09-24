{
  lib,
  aerospaceLib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.window-managers.darwin.aerospace;
in
{
  config = lib.mkIf cfg.enable {
    services.aerospace.settings.on-window-detected = aerospaceLib.mkRules [
      {
        appId = "org.mozilla.firefox";
        run = [ (aerospaceLib.mvNodeToWorkspace 1) ];
      }
      {
        appId = "org.gnu.Emacs";
        furtherCallbacks = false;
        run = [ (aerospaceLib.mkLayout "tiling") ];
      }
      {
        appId = "org.alacritty";
        run = [ (aerospaceLib.mvNodeToWorkspace 2) ];
      }
      {
        appId = "com.mitchellh.ghostty";
        run = [ (aerospaceLib.mvNodeToWorkspace 2) ];
      }
      {
        appId = "com.raphaelamorim.rio";
        run = [ (aerospaceLib.mvNodeToWorkspace 2) ];
      }
      {
        appId = "com.microsoft.VSCode";
        run = [ (aerospaceLib.mvNodeToWorkspace 3) ];
      }
      {
        appId = "net.whatsapp.WhatsApp";
        run = [ (aerospaceLib.mvNodeToWorkspace 4) ];
      }
      {
        appId = "com.openai.chat";
        run = [ (aerospaceLib.mvNodeToWorkspace 4) ];
      }
      { run = [ (aerospaceLib.mkLayout "floating") ]; }
    ];
  };
}
