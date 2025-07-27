{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.shells.tmux;
in
{
  options.${namespace}.shells.tmux = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      inherit (cfg) enable;

      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      customPaneNavigationAndResize = true;
      disableConfirmationPrompt = true;
      escapeTime = 0;
      focusEvents = true;
      mouse = true;
      newSession = true;
      shortcut = "b";
      terminal = "tmux-256color";
      extraConfig = ''
        set -g status-position top
        set -g status-right-length 100
        set -g status-left-length 100
        bind -N "Reload tmux configuration" R source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config reloaded!"
      '';
    };

    home.shellAliases.tmux = "cd && ${lib.getExe config.programs.tmux.package} attach"; # ensure tmux is started at ~
  };
}
