{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool' mkOptDisabled';

  cfg = config.${namespace}.shells.zellij;
in
{
  imports = [
    ./keybinds.nix
    ./themes.nix
    ./plugins.nix
    ./layouts.nix
  ];

  options.${namespace}.shells.zellij = {
    enable = mkOptBool';
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
      zll = "cd && zellij"; # ensure zellij is started at ~
      zllk = "pkill -x zellij";
    };
  };
}
