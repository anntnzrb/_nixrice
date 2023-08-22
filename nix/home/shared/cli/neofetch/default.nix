{ me
, pkgs
, inputs
, ...
}: {
  home.packages = [ pkgs.neofetch ];

  xdg.configFile = {
    "neofetch" = {
      enable = true;
      target = "neofetch";
      recursive = true;
      source = "${me.dotfilesDir}/neofetch";
    };
  };
}
