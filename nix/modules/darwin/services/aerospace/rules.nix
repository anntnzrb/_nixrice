{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.aerospace;

  /**
    Create an Aerospace rule for window matching and callback execution.

    # Example

    ```nix
    mkRule {
      appId = "org.mozilla.firefox";
      run = [ (mvNodeToWorkspace 1) ];
    }
    =>
    {
      "if" = { "app-id" = "org.mozilla.firefox"; };
      run = [ "move-node-to-workspace 1" ];
      "check-further-callbacks" = true;
    }
    ```

    # Type

    ```
    mkRule :: { appId :: String, appName :: String, windowTitle :: String, workspace :: String, duringStartup :: Bool, furtherCallbacks :: Bool, run :: [String] } -> AttrSet
    ```

    # Arguments

    appId
    : The application bundle ID to match (e.g., "org.mozilla.firefox")

    appName
    : Regex substring to match against application name

    windowTitle
    : Regex substring to match against window title

    workspace
    : Workspace name to match against

    duringStartup
    : Whether to apply the rule during Aerospace startup

    furtherCallbacks
    : Whether to continue checking further rules after this one (default: true)

    run
    : List of commands to execute when the rule matches
  */
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

  /**
    Apply mkRule to a list of rule definitions.

    # Example

    ```nix
    mkRules [
      { appId = "org.mozilla.firefox"; run = [ (mvNodeToWorkspace 1) ]; }
      { appId = "com.apple.Terminal"; run = [ (mvNodeToWorkspace 2) ]; }
    ]
    =>
    [
      { "if" = { "app-id" = "org.mozilla.firefox"; }; run = [ "move-node-to-workspace 1" ]; "check-further-callbacks" = true; }
      { "if" = { "app-id" = "com.apple.Terminal"; }; run = [ "move-node-to-workspace 2" ]; "check-further-callbacks" = true; }
    ]
    ```

    # Type

    ```
    mkRules :: [AttrSet] -> [AttrSet]
    ```

    # Arguments

    rules
    : List of rule attribute sets to be processed by mkRule
  */
  mkRules = rules: (map mkRule rules);

  /**
    Generate an Aerospace layout command string.

    # Example

    ```nix
    mkLayout "floating"
    =>
    "layout floating"

    mkLayout "split-grid"
    =>
    "layout split-grid"
    ```

    # Type

    ```
    mkLayout :: String -> String
    ```

    # Arguments

    name
    : The layout name (e.g., "floating", "split-grid", "bsp")
  */
  mkLayout = name: "layout ${name}";

  /**
    Generate an Aerospace move-node-to-workspace command string.

    # Example

    ```nix
    mvNodeToWorkspace 1
    =>
    "move-node-to-workspace 1"

    mvNodeToWorkspace 3
    =>
    "move-node-to-workspace 3"
    ```

    # Type

    ```
    mvNodeToWorkspace :: Int -> String
    ```

    # Arguments

    n
    : The workspace number to move the node to
  */
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
