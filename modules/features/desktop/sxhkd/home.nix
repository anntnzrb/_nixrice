{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) str ints;
  inherit (config.liberion.desktop.session) apps;

  cfg = config.liberion.desktop.sxhkd;
in
{
  imports = [ inputs.self.homeModules.session ];

  options.liberion.desktop.sxhkd = {
    timeout = mkOpt' ints.unsigned 3;
    cancelKey = mkOpt' str "Escape";
  };

  config = {
    services.sxhkd = {
      enable = true;

      extraOptions = [
        "-m 1"
        "-t ${toString cfg.timeout}"
        "-a ${cfg.cancelKey}"
      ];
      keybindings = {
        "super + Return ; {Return}" = "${lib.getExe apps.terminal} {_}";

        "super + w ; {f,w}" =
          "{${lib.getExe apps.fileManager},${lib.getExe apps.browser}}";

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
