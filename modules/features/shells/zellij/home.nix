{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.shells.zellij;
in
{
  imports = [
    ./layouts.nix
    ./plugins.nix
    ./themes.nix
  ];

  options.liberion.shells.zellij = {
    enableBashIntegration = mkOptDisabled';
    enableZshIntegration = mkOptDisabled';
    enableFishIntegration = mkOptDisabled';
  };

  config = {
    xdg.configFile."zellij/config.kdl".text = import ./keybinds.nix;

    programs.zellij = {
      enable = true;
      inherit (cfg) enableBashIntegration enableZshIntegration enableFishIntegration;

      settings = {
        default_mode = "locked";
        simplified_ui = false;
        default_cwd = "${config.home.homeDirectory}";
        mouse_mode = true;
        pane_frames = false;
        on_force_close = "detach";
        scroll_buffer_size = 10000;
        copy_clipboard = "primary";
        copy_on_select = true;
        attach_to_session = true;
      };
    };

    home.shellAliases = {
      zll = "cd && ${lib.getExe config.programs.zellij.package}"; # ensure zellij is started at ~
      zllk = "${lib.getExe pkgs.killall} zellij";
    };
  };
}
