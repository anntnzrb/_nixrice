{ palettes }:
let
  px = n: { px = n; };
  geometry = {
    defaultWidth = 320;
    minWidth = 44;
    macCollapsed = 76;
    maxWidth = 480;
    radius = 3;
    gap = 10;
  };
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
          (role "brand" "chrome" { inherit geometry; })
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
      size = px geometry.defaultWidth;
      min = geometry.minWidth;
      max = geometry.maxWidth;
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
                  inherit (geometry) radius gap;
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
                    (mod "changes" "changes")
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
          padding = geometry.gap;
          inherit (geometry) gap;
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
