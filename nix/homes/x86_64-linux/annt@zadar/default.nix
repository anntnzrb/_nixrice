{lib, ...}: let
  inherit (lib.liberion) on;
in {
  home.stateVersion = "23.05";

  liberion = {
    user.username = "annt";

    desktop = {
      feh = on;
      fonts = on;
      mpv = on;
      pcmanfm = on;
      picom = on;
      redshift = on;
      rofi = on;
      sxhkd = on;
      window-manager.awesome = on;

      browser = {
        firefox = on;
      };

      themes = {
        enable = true;
      };
    };

    shell = {
      bash = on;
      fish = on;
    };

    cli = {
      direnv = on;
      neofetch = on;
      starship = on;
      rust-utils = on;
    };

    editor = {
      neovim = on;
    };
  };
}
