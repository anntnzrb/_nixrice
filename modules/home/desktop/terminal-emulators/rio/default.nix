{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';

  cfg = config.liberion.desktop.terminal-emulators.rio;

  family = "Iosevka Comfy Motion";
  face = style: weight: { inherit family style weight; };

  themes = {
    catppuccin-mocha = inputs.rio-catppuccin + "/themes/catppuccin-mocha.toml";
    dracula = inputs.rio-dracula + "/dracula.toml";
  };

  key = key: mods: action: {
    inherit key action;
    "with" = mods;
  };
in
{
  options.liberion.desktop.terminal-emulators.rio = {
    enable = mkOptDisabled';
    font.size = mkOpt' lib.types.int 15;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.iosevka-comfy.comfy-motion
      pkgs.nerd-fonts.zed-mono
    ];

    xdg.configFile = lib.mapAttrs' (
      name: src:
      lib.nameValuePair "rio/themes/${name}.toml" { text = lib.readFile src; }
    ) themes;

    programs.rio = {
      enable = true;
      settings = {
        option-as-alt = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isDarwin "both";
        use-fork = false; # prefer clean process
        confirm-before-quit = false;
        hide-cursor-when-typing = false;
        theme = "catppuccin-mocha";

        editor = {
          program = "${config.home.sessionVariables.EDITOR}";
          args = [ ];
        };

        fonts = {
          inherit (cfg.font) size;
          regular = face "Normal" 400;
          bold = face "Normal" 800;
          italic = face "Italic" 400;
          bold-italic = face "Italic" 800;
        };

        padding-x = 0;
        padding-y = [
          0
          0
        ];
        line-height = 1.0;

        cursor = {
          blinking = true;
          blinking-interval = 400;
        };

        window = {
          opacity = 0.8;
          blur = true;
          decorations = "Buttonless";
        };

        renderer = {
          performance = "high";
          backend = "automatic";
          disable-unfocused-render = true; # TODO: test
          level = 1; # fonts/ligatures/emojis
        };

        scroll = {
          multiplier = 3.0;
          divider = 1.0;
        };

        navigation.mode = "Plain";

        bindings.keys = [
          (key "c" "control | shift" "Copy")
          (key "v" "control | shift" "Paste")
          (key "=" "control" "IncreaseFontSize")
          (key "-" "control" "DecreaseFontSize")
        ];
      };
    };
  };
}
