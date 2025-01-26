let
  layoutsDir = "zellij/layouts";

  # layout generator
  mkLayout = name: text: {
    "${layoutsDir}/${name}.kdl" = {
      inherit text;
    };
  };

in
#mkLayouts = layouts: lib.foldl (acc: layout: acc // (mkLayout layout)) { } layouts;
{
  config.programs.zellij.settings.default_layout = "def";

  config.xdg.configFile =
    mkLayout "base" ''
      layout {

          pane size=1 borderless=true {
              plugin location="tab-bar"
          }
          pane
          pane size=1 borderless=true {
              plugin location="status-bar"
          }

      }
    ''
    // mkLayout "def" ''
      layout {
          default_tab_template {
              pane size=1 borderless=true {
                  plugin location="zellij:tab-bar"

              }


              children


              pane size=1 borderless=true {
                  plugin location="zellij:status-bar"
              }

          }

          // ------------------------------------------------------------------

          pane_template name="tmpl-pane-slaves" {
              pane split_direction="horizontal" {
                  pane name="s0"
                  pane name="s1"
              }
          }

          // ------------------------------------------------------------------

          // tab 1
          // ------------------------------------------------------------------

          tab name="i" focus=true {
              pane split_direction="vertical" {
                  pane name="main" {
                      size "60%"
                      focus true
                  }
                  tmpl-pane-slaves
              }
          }




          // ------------------------------------------------------------------
          // tab 2
          // ------------------------------------------------------------------
          tab name="ii" {
              pane split_direction="vertical" {
                  pane name="main" {

                      size "60%"

                      focus true
                  }
                        pane name="s0"
              }
          }
      }
    '';
}
