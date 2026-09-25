{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) str ints;
  inherit (config.home.sessionVariables) TERMINAL FILE BROWSER;

  cfg = config.liberion.desktop.sxhkd;
in
{
  options.liberion.desktop.sxhkd = {
    enable = mkOptDisabled';

    timeout = mkOpt' ints.unsigned 3;
    cancelKey = mkOpt' str "Escape";
  };

  config = lib.mkIf cfg.enable {
    # apps the bindings launch; a host overrides them via home.sessionVariables
    home.sessionVariables = lib.mapAttrs (_: lib.mkDefault) {
      TERMINAL = "alacritty";
      FILE = "pcmanfm";
      BROWSER = "firefox";
    };

    services.sxhkd = {
      inherit (cfg) enable;

      extraOptions = [
        "-m 1"
        "-t ${toString cfg.timeout}"
        "-a ${cfg.cancelKey}"
      ];
      keybindings = {
        "super + Return ; {Return}" = "${TERMINAL} {_}";

        "super + w ; {f,w}" = "{${FILE},${BROWSER}}";

        "XF86AudioMute" = "pamixer -t";
        "XF86Audio{Lower,Raise}Volume" = "pamixer -{d,i} 5";

        "XF86MonBrightness{Down,Up}" = "brightnessctl set {2%-,+2%}";

        "super + Escape ; {x}" = "{pkill -15 'X'}";
      };
    };

    home.activation = {
      reloadSxhkd = config.lib.dag.entryAfter [
        "writeBoundary"
      ] "${pkgs.procps}/bin/pkill -USR1 sxhkd || :";
    };
  };
}
