{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.shared.xorg;
in
{
  options.${namespace}.shared.xorg = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    xsession = {
      inherit (cfg) enable;
      profilePath = ".config/xorg/xprofile-hm";
      scriptPath = ".config/xorg/xsession-hm";

      initExtra = with config.${namespace}.home.keyboard; ''
        ${lib.getExe pkgs.xorg.xset} r rate ${toString autoRepeatDelay} ${toString autoRepeatInterval}
      '';
    };

    home = {
      sessionVariables = {
        XAUTHORITY = "${config.xdg.stateHome}/.Xauthority";
      };
      shellAliases = {
        startx = "printf 'Do not use this command. Use the appropriate wrapper for launching the graphic environment.\n' >&2";
      };

      packages = with pkgs; [
        xclip
        arandr
        xorg.xev
        xorg.xprop
      ];
    };
  };
}
