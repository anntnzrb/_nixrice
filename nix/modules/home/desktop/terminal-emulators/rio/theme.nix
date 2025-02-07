{
  inputs,
  lib,
  ...
}:
let
  themeDir = "rio/themes";

  themes = with inputs; {
    catppuccin-mocha = rio-catppuccin + "/themes/catppuccin-mocha.toml";
    dracula = rio-dracula + "/dracula.toml";
  };
in
{
  config = {
    xdg.configFile = lib.mapAttrs' (
      name: src:
      lib.nameValuePair "${themeDir}/${name}.toml" { text = lib.readFile src; }
    ) themes;

    programs.rio.settings.theme = "catppuccin-mocha";
  };
}
