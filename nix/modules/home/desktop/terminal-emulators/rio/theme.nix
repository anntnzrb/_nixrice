{
  inputs,
  lib,
  ...
}:
let
  themeDir = "rio/themes";

  themes = {
    catppuccin-mocha = "${inputs.rio-catppuccin}/themes/catppuccin-mocha.toml";
    dracula = "${inputs.rio-dracula}/dracula.toml";
  };
in
{
  config = {
    xdg.configFile = lib.mapAttrs' (
      name: src: lib.nameValuePair "${themeDir}/${name}.toml" { text = builtins.readFile src; }
    ) themes;

    programs.rio.settings.theme = "catppuccin-mocha";
  };
}
