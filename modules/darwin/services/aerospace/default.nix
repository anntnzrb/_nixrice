{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.services.aerospace;

  mod = "alt";
  vim = {
    h = "left";
    j = "down";
    k = "up";
    l = "right";
  };
  workspaces = lib.genAttrs (map toString (lib.range 0 9)) lib.id;

  # { key = arg; } -> { "<mods>-<key>" = "<command> <arg>"; }
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
in
{
  options.liberion.services.aerospace.enable = mkOptDisabled';

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.liberion.services.yashiki.enable;
        message = "liberion.services.aerospace cannot be enabled together with liberion.services.yashiki.";
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
          (toWorkspace 4 "net.whatsapp.WhatsApp")
          (toWorkspace 4 "com.openai.chat")
          (rule { } [ "layout floating" ])
        ];
      };
    };

    launchd.user.agents.aerospace.serviceConfig = {
      ProcessType = "Interactive";
      LimitLoadToSessionType = [ "Aqua" ];
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      if [ -n "''${SUDO_USER:-}" ]; then
        user="''${SUDO_USER}"
      else
        user="${config.system.primaryUser}"
      fi

      uid="$(id -u "$user" 2>/dev/null || true)"
      if [ -n "$uid" ]; then
        launchctl bootout "gui/$uid/org.nixos.yashiki" >/dev/null 2>&1 || :
      fi

      ${pkgs.yashiki}/bin/yashiki stop >/dev/null 2>&1 || :
    '';

    # goodies
    # cf. https://nikitabobko.github.io/AeroSpace/goodies
    system.defaults.NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      NSAutomaticWindowAnimationsEnabled = true;
    };
  };
}
