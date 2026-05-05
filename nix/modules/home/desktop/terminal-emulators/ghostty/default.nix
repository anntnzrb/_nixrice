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
    mkOpt'
    mkOptDisabled'
    ;
  inherit (lib.types)
    nullOr
    str
    ;

  ghosttyDir = "ghostty";
  ghosttyConfigHome = "${config.xdg.configHome}/${ghosttyDir}";
  themesDir = "${ghosttyDir}/themes";

  cfg = config.${namespace}.desktop.terminal-emulators.ghostty;

  normalizeLocalConfigFile =
    value:
    if value == null then
      null
    else
      let
        optional = lib.hasPrefix "?" value;
        raw = if optional then lib.removePrefix "?" value else value;
        abs = if lib.hasPrefix "/" raw then raw else "${ghosttyConfigHome}/${raw}";
      in
      if optional then "?${abs}" else abs;

  localConfigFile = normalizeLocalConfigFile cfg.localConfigFile;
in
{
  options.${namespace}.desktop.terminal-emulators.ghostty = {
    enable = mkOptDisabled';
    localConfigFile = mkOpt' (nullOr str) "?local.conf";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."${themesDir}".source = inputs.ghostty-protesilaos + "/themes";

    programs.ghostty = {
      inherit (cfg) enable;

      installBatSyntax = true;

      package =
        if pkgs.stdenvNoCC.hostPlatform.isDarwin then
          inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ghostty-bin
        else
          pkgs.ghostty;
      clearDefaultKeybinds = true;
      settings = {
        theme = "ef-elea-light";
        font-size = 16;
        macos-option-as-alt = true;
        keybind = [
          "shift+enter=text:\n" # newline
          "super+c=copy_to_clipboard"
          "super+v=paste_from_clipboard"
          "super+comma=open_config"
          "super+n=new_window"
          "super+t=new_tab"
          "super+digit_1=goto_tab:1"
          "super+1=goto_tab:1"
          "super+digit_2=goto_tab:2"
          "super+2=goto_tab:2"
          "super+digit_3=goto_tab:3"
          "super+3=goto_tab:3"
          "super+digit_4=goto_tab:4"
          "super+4=goto_tab:4"
          "super+digit_5=goto_tab:5"
          "super+5=goto_tab:5"
          "super+digit_6=goto_tab:6"
          "super+6=goto_tab:6"
          "super+digit_7=goto_tab:7"
          "super+7=goto_tab:7"
          "super+digit_8=goto_tab:8"
          "super+8=goto_tab:8"
          "super+q=quit"
          "super+w=close_window"

          "super+equal=increase_font_size:1"
          "super+plus=increase_font_size:1"
          "super+minus=decrease_font_size:1"
          "super+zero=reset_font_size"
          "super+ctrl+f=toggle_fullscreen"

        ];
      }
      // lib.optionalAttrs (localConfigFile != null) {
        "config-file" = localConfigFile;
      };
    };
  };
}
