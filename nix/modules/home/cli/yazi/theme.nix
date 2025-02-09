{
  lib,
  inputs,
  ...
}:
let
  inherit (inputs)
    yazi-flavors
    yazi-timu-macos
    ;

  themeDir = "yazi/flavors";

  themes = {
    dracula = yazi-flavors + "/dracula.yazi";
    catppuccin-macchiato = yazi-flavors + "/catppuccin-macchiato.yazi";
    timu-macos-dark = yazi-timu-macos + "/timu-macos-dark.yazi";
  };
in
{
  config.xdg.configFile = lib.mapAttrs' (
    name: src: lib.nameValuePair "${themeDir}/${name}.yazi" { source = src; }
  ) themes;

  config.programs.yazi.theme.flavor.use = "timu-macos-dark";
}
