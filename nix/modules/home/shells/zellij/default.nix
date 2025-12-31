{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' getModuleFiles;

  cfg = config.${namespace}.shells.zellij;
in
{
  imports = getModuleFiles { path = ./.; };

  options.${namespace}.shells.zellij = {
    enable = mkOptDisabled';
    enableBashIntegration = mkOptDisabled';
    enableZshIntegration = mkOptDisabled';
    enableFishIntegration = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      inherit (cfg)
        enable
        enableBashIntegration
        enableZshIntegration
        enableFishIntegration
        ;

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
      zllk = "pkill -x zellij";
    };
  };
}
