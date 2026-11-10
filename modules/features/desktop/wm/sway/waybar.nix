{ lib, ... }: {
  programs.waybar = {
    enable = true;
    style = lib.readFile ./style.css;
    settings.default = {
      position = "top";
      modules-left = [ "sway/workspaces" ];
      modules-center = [ ];
      modules-right = [
        "cpu"
        "memory"
        "tray"
        "clock"
      ];
      clock = {
        format = "  {:%a, %d/%m %R}";
        tooltip-format = "{:%Y-%m-%d}";
      };
      cpu = {
        interval = 10;
        format = "  {usage}%";
      };
      memory = {
        interval = 10;
        format = "  {percentage}%";
      };
      tray.spacing = 5;
    };
  };
}
