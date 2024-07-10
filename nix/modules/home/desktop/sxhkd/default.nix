{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.liberion.desktop.sxhkd;
in
{
  options.liberion.desktop.sxhkd =
    with lib.liberion;
    with lib.types;
    {
      enable = mkOptBool';

      timeout = mkOpt' ints.unsigned 3;
      cancelKey = mkOpt' str "Escape";
    };

  config = lib.mkIf cfg.enable {
    services.sxhkd = {
      enable = true;

      extraOptions = [
        "-m 1"
        "-t ${toString cfg.timeout}"
        "-a ${cfg.cancelKey}"
      ];
      keybindings = with config.home.sessionVariables; {
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
