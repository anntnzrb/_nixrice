{ pkgs, ... }: {
  home.packages = with pkgs; [
    xclip
  ];

  services.picom = {
    enable = true;
    backend = "glx";
    vSync = false;

    # opacity
    activeOpacity = 1.0;
    inactiveOpacity = 1.0;
    menuOpacity = 1.0;

    fade = true;
    fadeDelta = 6;
    shadow = true;
    shadowOpacity = 0.8;
  };
}
