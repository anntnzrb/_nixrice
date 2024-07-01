{ config
, lib
, namespace
, ...
}:
let
  cfg = config.${namespace}.darwin.homebrew;
in
{
  options.${namespace}.darwin.homebrew = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;
      global.autoUpdate = false;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "zap";
      };

      casks = [
        "alacritty"
        "bitwarden"
        "chatgpt"
        "firefox"
        "notesnook"

        # dev
        "visual-studio-code"

        # misc
        "whatsapp"

        # system
        "aldente"
      ];
    };
  };
}
