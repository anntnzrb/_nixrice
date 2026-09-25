{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
  ghosttyPackage =
    if isDarwin then
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ghostty-bin
    else
      pkgs.ghostty;
  # Ghostty's Darwin bundle ships numeric terminfo dirs; compiling a small DB
  # keeps consumers like Codex from failing terminal capability lookup.
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

  programs.ghostty = {
    enable = true;

    installBatSyntax = true;

    package = ghosttyPackage;
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
      ]
      # super+{digit_,}N switches to tab N
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
    // lib.optionalAttrs isDarwin {
      # Prefer the normalized store DB over Ghostty's app-bundle TERMINFO.
      env = "TERMINFO=${ghosttyTerminfo}";
    }
    // {
      "config-file" = "?${config.xdg.configHome}/ghostty/local.conf";
    };
  };
}
