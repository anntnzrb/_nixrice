{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.window-manager.awesome;
in {
  options.liberion.desktop.window-manager.awesome = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    xsession = {
      enable = true;
      windowManager.awesome.enable = true;
    };

    home.packages = with pkgs; [
      (writeShellApplication {
        name = "awesome-start";
        runtimeInputs = [sx];

        text = "sx ${config.liberion.user.homeDirectory}/.config/awesome/autostart.sh";
      })
    ];

    xdg.configFile = {
      "awesome" = {
        enable = true;
        source = ./config/awesome;
        target = "awesome";
        recursive = true;
      };
    };
  };
}
