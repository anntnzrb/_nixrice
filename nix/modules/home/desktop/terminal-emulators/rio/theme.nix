{
  inputs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.terminal-emulators.rio;
  themeDir = "rio/themes";

  themes = with inputs; {
    catppuccin-mocha = rio-catppuccin + "/themes/catppuccin-mocha.toml";
    dracula = rio-dracula + "/dracula.toml";
  };
in
lib.mkIf cfg.enable {
  xdg.configFile = lib.mapAttrs' (
    name: src:
    lib.nameValuePair "${themeDir}/${name}.toml" { text = lib.readFile src; }
  ) themes;

  programs.rio.settings.theme = "catppuccin-mocha";
}
