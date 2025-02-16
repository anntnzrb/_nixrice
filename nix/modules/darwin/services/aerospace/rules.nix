{
  lib,
  ...
}:
let
  mkRule =
    {
      appId ? null,
      appName ? null,
      windowTitle ? null,
      workspace ? null,

      duringStartup ? null,
      furtherCallbacks ? false,

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
  config.services.aerospace.settings.on-window-detected = mkRules [
    {
      # Finder
      appId = "com.apple.finder";
      run = [ (mkLayout "floating") ];
      furtherCallbacks = true;
    }
    {
      # Bitwarden
      appId = "com.bitwarden.desktop";
      run = [
        (mkLayout "floating")
        (mvNodeToWorkspace 1)
      ];
      furtherCallbacks = true;
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
    {
      # Docker (Desktop)
      appId = "com.electron.dockerdesktop";
      run = [ (mkLayout "floating") ];
      furtherCallbacks = true;
    }
    {
      # RustDesk
      appId = "com.carriez.rustdesk";
      run = [ (mkLayout "floating") ];
      furtherCallbacks = true;
    }

    # fallback rule
    # foreign nodes go to scratch/dumpster/whatever workspace
    # do not mess with my setup
    {
      run = [ (mvNodeToWorkspace 0) ];
    }
  ];
}
