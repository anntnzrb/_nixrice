let
  layoutsDir = "zellij/layouts";
in
{
  config.xdg.configFile."${layoutsDir}".source = ./layouts;
}
