{ me
, pkgs
, inputs
, ...
}: {
  xsession.windowManager.awesome.enable = true;

  xdg.configFile = {
    "awesome" = {
      enable = true;
      target = "awesome";
      recursive = true;
      source = "${me.dotfilesDir}/awesome";
    };
  };
}
