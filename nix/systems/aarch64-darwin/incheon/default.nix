{
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) on;
in
{
  # zsh as an interactive shell; this is a forced default
  # customization is done via hm
  programs.zsh.enable = true;

  ${namespace} = {
    system = {
      trackpad = on;
      ui.menuBar.hide = false;
    };

    services = {
      aerospace = on;

      skhd = {
        enable = true;
        keybindings =
          let
            mod = "alt";
          in
          {
            "${mod} - return" = "open -na ${lib.getExe pkgs.alacritty}";
          };
      };
    };

    homebrew = {
      enable = true;

      packages = {
        casks = [
          # apps
          "bitwarden"
          "chatgpt"
          "firefox"
          "whatsapp"
          "obs"
          "docker"
          "transmission"
          "vlc"
          "ghostty"

          # dev
          "visual-studio-code"
          "rustdesk"

          # situational
          #"microsoft-teams"
          #"microsoft-word"
          #"zoom"
        ];
      };
    };
  };
}
