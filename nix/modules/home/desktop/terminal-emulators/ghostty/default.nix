{
  pkgs,
  lib,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;

  themesDir = "ghostty/themes";

  cfg = config.${namespace}.desktop.terminal-emulators.ghostty;
in
{
  options.${namespace}.desktop.terminal-emulators.ghostty = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."${themesDir}".source = inputs.ghostty-protesilaos + "/themes";

    programs.ghostty = {
      inherit (cfg) enable;

      installBatSyntax = true;

      package =
        if pkgs.stdenvNoCC.hostPlatform.isDarwin then
          inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.ghostty-bin
        else
          pkgs.ghostty;
      clearDefaultKeybinds = true;
      settings = {
        theme = "ef-melissa-light";
        font-size = 16;
        keybind = [
          "shift+enter=text:\n" # newline
          "super+c=copy_to_clipboard"
          "super+v=paste_from_clipboard"
          "super+comma=open_config"
          "super+n=new_window"
          "super+q=quit"
          "super+w=close_window"

          "super+equal=increase_font_size:1"
          "super+plus=increase_font_size:1"
          "super+minus=decrease_font_size:1"
          "super+zero=reset_font_size"

        ];
      };
    };
  };
}
