{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.aerospace;

  mkRule =
    {
      appId ? null,
      appName ? null,
      windowTitle ? null,
      workspace ? null,

      duringStartup ? null,
      furtherCallbacks ? true,

      run,
    }:
    {
      "if" = lib.filterAttrs (_: v: v != null) {
        "app-id" = appId;
        "app-name-regex-substring" = appName;
        "window-title-regex-substring" = windowTitle;
        "during-aerospace-startup" = duringStartup;
        inherit workspace;
      };
      inherit run;
      "check-further-callbacks" = furtherCallbacks;
    };

  mkRules = rules: (map mkRule rules);

  # helpers
  mkLayout = name: "layout ${name}";
  mvNodeToWorkspace = n: "move-node-to-workspace ${builtins.toString n}";
in
{
  config = lib.mkIf cfg.enable {
    services.aerospace.settings.on-window-detected = mkRules [
      {
        # Browser: Firefox
        appId = "org.mozilla.firefox";
        run = [ (mvNodeToWorkspace 1) ];
      }
      {
        # Terminal: Alacritty
        appId = "org.alacritty";
        run = [ (mvNodeToWorkspace 2) ];
      }
      {
        # Terminal: Ghostty
        appId = "com.mitchellh.ghostty";
        run = [ (mvNodeToWorkspace 2) ];
      }
      {
        # Terminal: Rio
        appId = "com.raphaelamorim.rio";
        run = [ (mvNodeToWorkspace 2) ];
      }
      {
        # VSCode
        appId = "com.microsoft.VSCode";
        run = [ (mvNodeToWorkspace 3) ];
      }
      {
        # WhatsApp
        appId = "net.whatsapp.WhatsApp";
        run = [ (mvNodeToWorkspace 4) ];
      }
      {
        # ChatGPT
        appId = "com.openai.chat";
        run = [ (mvNodeToWorkspace 4) ];
      }
      # default rule: make all other windows floating anywhere
      {
        run = [ (mkLayout "floating") ];
      }
    ];
  };
}
