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
      newSession = false;
      shortcut = "b";
      terminal = "tmux-256color";
      extraConfig = ''
        set -g status-position top

        set -g status-style bg=default,fg=default
        set -g status-justify left
        set -g automatic-rename off
        set -g status-left '[#S] '
        set -g status-right ' '
        setw -g window-status-format '#I#F'
        setw -g window-status-current-format '#[bold]#I#F'

        bind -N "Reload tmux configuration" R source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config reloaded!"
      '';
    };
  };
}
