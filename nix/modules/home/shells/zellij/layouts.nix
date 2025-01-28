{
  lib,
  ...
}:
let
  layoutsDir = "zellij/layouts";

  # layout generator
  mkLayout = name: text: {
    "${layoutsDir}/${name}.kdl" = { inherit text; };
  };

  mkLayouts =
    names: lib.foldl (acc: name: acc // (mkLayout name (import ./layouts/${name}.nix))) { } names;
in
{
  config.programs.zellij.settings.default_layout = "welcome";

  config.xdg.configFile = mkLayouts [
    "base"
    "rice"
  ];
}
