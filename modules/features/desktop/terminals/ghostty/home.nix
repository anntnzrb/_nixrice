{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
  ghosttyPackage =
    if isDarwin then
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ghostty-bin
    else
      pkgs.ghostty;
  ghosttyTerminfo =
    pkgs.runCommand "ghostty-terminfo" { nativeBuildInputs = [ pkgs.ncurses ]; }
      ''
        mkdir -p "$out"
        infocmp -A "${ghosttyPackage}/Applications/Ghostty.app/Contents/Resources/terminfo" xterm-ghostty \
          | tic -x -o "$out" -
      '';
in
{
  xdg.configFile."ghostty/themes".source = inputs.ghostty-protesilaos + "/themes";

  home.file.".local/bin/ghostty" = lib.mkIf isDarwin {
    executable = true;
    text = ''
      #!/bin/sh
      exec /Applications/Ghostty.app/Contents/MacOS/ghostty "$@"
    '';
  };

  programs.ghostty = {
    enable = true;

    package = if isDarwin then null else ghosttyPackage;
    clearDefaultKeybinds = true;
    settings = {
      theme = "ef-elea-light";
      font-size = 16;
      macos-option-as-alt = true;
      keybind = [
        "shift+enter=text:\n"
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "super+comma=open_config"
        "super+n=new_window"
        "super+t=new_tab"
      ]
      ++ lib.concatMap (
        n:
        map (key: "super+${key}${n}=goto_tab:${n}") [
          "digit_"
          ""
        ]
      ) (map toString (lib.range 1 8))
      ++ [
        "super+q=quit"
        "super+w=close_surface"

        "super+equal=increase_font_size:1"
        "super+plus=increase_font_size:1"
        "super+minus=decrease_font_size:1"
        "super+zero=reset_font_size"
        "super+ctrl+f=toggle_fullscreen"
      ];
    }
    // lib.optionalAttrs isDarwin { env = "TERMINFO=${ghosttyTerminfo}"; }
    // {
      "config-file" = "?${config.xdg.configHome}/ghostty/local.conf";
    };
  };
}
