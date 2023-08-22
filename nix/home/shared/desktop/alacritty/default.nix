{ me
, pkgs
, inputs
, ...
}: {
  programs.alacritty.enable = true;

  xdg.configFile = {
    "alacritty" = {
      enable = true;
      target = "alacritty";
      recursive = true;
      source = "${me.dotfilesDir}/alacritty";
    };
  };
}
