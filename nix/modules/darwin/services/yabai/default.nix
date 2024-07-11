{ config
, lib
, namespace
, ...
}:
let
  cfg = config.${namespace}.services.yabai;

  # helpers
  formatAttrs = with builtins; attrs: concatStringsSep " " (map (k: "${k}=${getAttr k attrs}") (attrNames attrs));
  mkRule = rule: "yabai -m rule --add ${formatAttrs rule.pattern} ${formatAttrs rule.ruleset}";

in
{
  options.${namespace}.services.yabai = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.yabai = {
      enable = true;

      config = {
        layout = "bsp";
        split_ratio = 0.5;
        focus_follows_mouse = "autofocus";

        # mouse
        mouse_modifier = "fn";
        mouse_follows_focus = "on"; # warp mouse?
        mouse_action1 = "move"; # mod + LMB
        mouse_action2 = "resize"; # mod + RMB

        # gaps
        top_padding = 10;
        bottom_padding = 10;
        left_padding = 15;
        right_padding = 15;
        window_gap = 15;
      };

      extraConfig =
        let
          rules = [
            # sys/builtin
            {
              pattern = { app = "^System Settings$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^System Information$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^System Preferences$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { title = "Preferences$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { title = "Settings$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Finder$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Terminal$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Calculator$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Notes$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Weather$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Calendar$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Clock$"; };
              ruleset = { manage = "off"; };
            }

            # user
            {
              pattern = { app = "^Alacritty$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^Bitwarden$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^ChatGPT$"; };
              ruleset = { manage = "off"; };
            }
            {
              pattern = { app = "^WhatsApp$"; };
              ruleset = { manage = "off"; };
            }
          ];
        in
        ''
          # rules
          ${builtins.concatStringsSep "\n" (map mkRule rules)}
        '';
    };

    ${namespace}.services.skhd = {
      enable = true;

      keybindings = {
        "alt - k" = "yabai -m window --focus north";
        "alt - l" = "yabai -m window --focus east";
        "alt - j" = "yabai -m window --focus south";
        "alt - h" = "yabai -m window --focus west";
      };
    };
  };
}
