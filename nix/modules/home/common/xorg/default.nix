{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg;

  parseAutoStartList = xs: builtins.concatStringsSep "\n" (map (x: x + " &") xs);
in
with lib;
{
  options.liberion.common.xorg = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    autoStart = mkOpt' (listOf str) [ ];
  };

  config = mkIf cfg.enable {
    xsession = {
      enable = true;
      #windowManager.command = lib.mkForce "";

      initExtra = parseAutoStartList cfg.autoStart;
      profilePath = ".config/xprofile-hm";
      scriptPath = ".config/xsession-hm";
    };

    home = {
      shellAliases = {
        startx = "printf 'Do not use this command. Use the appropiate wrapper for launching the graphic environment.\n' >2&1";
      };

      packages = with pkgs; [
        xclip
        arandr
      ];
    };
  };
}
