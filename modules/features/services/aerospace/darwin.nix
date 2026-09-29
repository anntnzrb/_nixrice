{
  lib,
  pkgs,
  config,
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

  wm = import ../_wm-handoff.nix {
    inherit lib;
    user = config.system.primaryUser;
  };

  evacuateYashiki = pkgs.writeShellApplication {
    name = "evacuate-yashiki";
    runtimeInputs = [
      pkgs.yashiki
      pkgs.gnugrep
    ];
    text = ''
      yashiki list-outputs | grep -oE '^[0-9]+' | while read -r id; do
        yashiki tag-view --output "$id" 1023
      done
    '';
  };
in
{
  config = {
    assertions = [
      {
        assertion = !(config.launchd.user.agents ? yashiki);
        message = "the aerospace feature cannot be imported together with the yashiki feature.";
      }
    ];

    services.aerospace = {
      enable = true;
      package = pkgs.aerospace;
      settings = {
        start-at-login = false;
        after-login-command = [ ];
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
          (
            rule { app-id = "org.gnu.Emacs"; } [ "layout tiling" ]
            // {
              check-further-callbacks = false;
            }
          )
          (toWorkspace 2 "org.alacritty")
          (toWorkspace 2 "com.mitchellh.ghostty")
          (toWorkspace 2 "com.raphaelamorim.rio")
          (toWorkspace 3 "com.microsoft.VSCode")
          (toWorkspace 4 "com.openai.chat")
          (rule { } [ "layout floating" ])
        ];
      };
    };

    launchd.user.agents.aerospace.serviceConfig = {
      ProcessType = "Interactive";
      LimitLoadToSessionType = [ "Aqua" ];
    };

    system.activationScripts.preActivation.text = lib.mkAfter (
      wm.stop {
        label = "org.nixos.yashiki";
        evacuate = lib.getExe evacuateYashiki;
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
