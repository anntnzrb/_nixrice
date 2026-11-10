{ palettes }:
let
  px = n: { px = n; };
  mod = id: name: {
    inherit id;
    type = "block";
    content.mod = name;
  };
  role =
    id: name: extra:
    (mod id "kindred")
    // {
      content = {
        mod = "kindred";
        props = {
          role = name;
        }
        // extra;
      };
    };
  line = color: {
    width = 1;
    inherit color;
  };
in
{
  id = "root";
  type = "row";
  children = [
    {
      id = "sidebar";
      type = "column";
      children = [
        (
          (role "brand" "chrome" { })
          // {
            size = px 46;
            window_drag = true;
          }
        )
        {
          id = "sidebar-lists";
          type = "column";
          children = [
            (
              (role "spaces" "spaces" { })
              // {
                size.weight = 0.8;
                min = 90;
              }
            )
            (
              (mod "agents" "kindred")
              // {
                size.weight = 1.2;
                min = 90;
              }
            )
          ];
        }
        ((role "sidebar-footer" "chrome" { footer = true; }) // { size = px 69; })
      ];
      size = px 320;
      min = 44;
      max = 480;
      background = "chrome";
      resizable = false;
    }
    {
      id = "work";
      type = "column";
      children = [
        (
          (role "tabs" "tabs" { })
          // {
            size = px 42;
            window_drag = true;
          }
        )
        {
          id = "work-body";
          type = "row";
          children = [
            {
              id = "main";
              type = "block";
              content = {
                tab = "active";
                pane = {
                  header = {
                    inherit (role "pane" "pane" { }) content;
                    reveal = "always";
                    height = 30;
                    position = "top";
                  };
                  background = "background";
                  border = line "border";
                  focus = line "accent";
                  radius = 3;
                  gap = 10;
                  lone = true;
                };
              };
            }
            {
              id = "panel";
              type = "column";
              children = [
                {
                  id = "panel-body";
                  type = "stack";
                  children = [
                    (mod "files" "files")
                    (
                      (mod "changes" "reviewer")
                      // {
                        content.props.palette = "theme";
                        content.mod = "reviewer";
                      }
                    )
                  ];
                  active = "files";
                }
              ];
              size = px 368;
              min = 280;
              max = 900;
              hidden = true;
            }
          ];
          padding = 10;
          gap = 10;
        }
      ];
      resizable = false;
    }
  ];
  background = "canvas";
  theme = builtins.mapAttrs (variant: _: "kindred-${variant}") palettes;
  ui_font = "Geist Mono";
  terminal_padding = [
    14
    12
  ];
  divider = line "border";
  titlebar = "none";
  traffic_lights = [
    12
    16
  ];
}
