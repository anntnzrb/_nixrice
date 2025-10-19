{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.shells.zellij;

  layoutsDir = "zellij/layouts";

  # layout generator
  mkLayout = name: text: {
    "${layoutsDir}/${name}.kdl" = { inherit text; };
  };

  mkLayouts =
    names:
    lib.foldl (
      acc: name: acc // (mkLayout name (import ./layouts/${name}.nix))
    ) { } names;
in
{
  config = lib.mkIf cfg.enable {
    programs.zellij.settings.default_layout = "welcome";

    xdg.configFile = mkLayouts [
      "base"
      "rice"
    ];
  };
}
