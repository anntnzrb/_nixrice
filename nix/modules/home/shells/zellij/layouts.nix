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
  /**
    Create a Zellij layout file from text content.

    # Example

    ```nix
    mkLayout "my-layout" ''
      layout {
        pane
      }
    ''
    =>
    {
      "zellij/layouts/my-layout.kdl" = {
        text = "layout {\n  pane\n}\n";
      };
    }
    ```

    # Type

    ```
    mkLayout :: String -> String -> AttrSet
    ```

    # Arguments

    name
    : The name of the layout file (without extension)

    text
    : The KDL content of the layout
  */
  mkLayout = name: text: {
    "${layoutsDir}/${name}.kdl" = { inherit text; };
  };

  /**
    Create multiple Zellij layout files from a list of names.

    # Example

    ```nix
    mkLayouts [ "base" "rice" ]
    =>
    {
      "zellij/layouts/base.kdl" = { text = ...; };
      "zellij/layouts/rice.kdl" = { text = ...; };
    }
    ```

    # Type

    ```
    mkLayouts :: [String] -> AttrSet
    ```

    # Arguments

    names
    : List of layout names to create (corresponding .nix files must exist in ./layouts/)
  */
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
