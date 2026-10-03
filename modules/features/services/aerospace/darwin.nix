{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  mod = "alt";
  vim = {
    h = "left";
    j = "down";
    k = "up";
    l = "right";
  };
  workspaces = lib.genAttrs (map toString (lib.range 0 9)) lib.id;

  bind =
    mods: command:
    lib.mapAttrs' (
      key: arg: lib.nameValuePair "${mods}-${key}" "${command} ${arg}"
    );

  rule = cond: run: {
    "if" = cond;
    inherit run;
    check-further-callbacks = true;
  };
  toWorkspace =
    n: appId: rule { app-id = appId; } [ "move-node-to-workspace ${toString n}" ];
  tile =
    n: appId:
    rule { app-id = appId; } [
      "move-node-to-workspace ${toString n}"
      "layout tiling"
    ]
    // {
      check-further-callbacks = false;
    };

  settings = {
    start-at-login = false;
    after-login-command = [ ];
    after-startup-command = [ ];
    default-root-container-layout = "tiles";
    default-root-container-orientation = "auto";
    enable-normalization-flatten-containers = true;
    enable-normalization-opposite-orientation-for-nested-containers = true;
    exec-on-workspace-change = [ ];
    key-mapping.preset = "qwerty";
    on-focus-changed = [ ];
    on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
    workspace-to-monitor-force-assignment = { };
    accordion-padding = 0;
    gaps = {
      inner = {
        horizontal = 8;
        vertical = 8;
      };
      outer = lib.genAttrs [ "top" "right" "bottom" "left" ] (_: 4);
    };

    mode.main.binding =
      bind mod "focus" vim
      // bind "${mod}-shift" "move" vim
      // bind mod "workspace" workspaces
      // bind "${mod}-shift" "move-node-to-workspace" workspaces
      // {
        "${mod}-shift-f" = "fullscreen";
        "${mod}-tab" = "workspace-back-and-forth";
        "${mod}-shift-tab" = "move-workspace-to-monitor --wrap-around next";
      };

    on-window-detected = [
      (toWorkspace 1 "org.mozilla.firefox")
      (tile 1 "com.brave.Browser")
      (toWorkspace 2 "org.alacritty")
      (tile 2 "com.mitchellh.ghostty")
      (toWorkspace 2 "com.raphaelamorim.rio")
      (rule { } [ "layout floating" ])
    ];
  };

  configFile = (pkgs.formats.toml { }).generate "aerospace.toml" settings;

  wm = import ../_wm-handoff.nix {
    inherit lib pkgs;
    user = config.system.primaryUser;
  };
in
{
  imports = [ inputs.self.darwinModules.homebrew ];

  config = {
    assertions = [
      {
        assertion = !(config.launchd.user.agents ? yashiki);
        message = "the aerospace feature cannot be imported together with the yashiki feature.";
      }
    ];

    liberion = {
      homebrew.apps = [ "aerospace" ];
      darwin.owned.privacy = [
        {
          service = "Accessibility";
          bundleId = "bobko.aerospace";
        }
      ];
    };

    launchd.user.agents.aerospace = {
      managedBy = "modules/features/services/aerospace";
      command = "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace --config-path ${configFile}";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
      };
    };

    system.activationScripts.preActivation.text = lib.mkAfter (
      wm.stop {
        label = "org.nixos.yashiki";
        evacuate = lib.getExe wm.unparkYashiki;
        leftovers = [
          "/tmp/yashiki.pid"
          "/tmp/yashiki.sock"
          "/tmp/yashiki-events.sock"
        ];
      }
    );

    system.defaults.NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      NSAutomaticWindowAnimationsEnabled = true;
    };
  };
}
