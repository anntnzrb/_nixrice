{
  lib,
  ...
}:
let
  mkRule =
    {
      appId ? null,
      appNameRegexSubstring ? null,
      checkFurtherCallbacks ? false,
      duringAerospaceStartup ? null,
      windowTitleRegexSubstring ? null,
      workspace ? null,
      run,
    }:
    {
      "if" = lib.filterAttrs (_: v: v != null) {
        "app-id" = appId;
        "app-name-regex-substring" = appNameRegexSubstring;
        "window-title-regex-substring" = windowTitleRegexSubstring;
        "during-aerospace-startup" = duringAerospaceStartup;
        inherit workspace;
      };
      inherit run;
      "check-further-callbacks" = checkFurtherCallbacks;
    };

  mkRules = rules: (map mkRule rules);

  # helpers
  mkLayout = name: "layout ${name}";
  mvNodeToWorkspace = n: "move-node-to-workspace ${builtins.toString n}";
in
{
  config.services.aerospace.settings.on-window-detected = mkRules [
    {
      # Finder
      appId = "com.apple.finder";
      run = [ (mkLayout "floating") ];
    }
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
      # WhatsApp
      appId = "net.whatsapp.WhatsApp";
      run = [ (mvNodeToWorkspace 9) ];
    }
    {
      # ChatGPT
      appId = "com.openai.chat";
      run = [ (mvNodeToWorkspace 8) ];
    }
    {
      # Docker (Desktop)
      appId = "com.electron.dockerdesktop";
      run = [ (mkLayout "floating") ];
    }
    {
      # RustDesk
      appId = "com.carriez.rustdesk";
      run = [ (mkLayout "floating") ];
    }
  ];
}
