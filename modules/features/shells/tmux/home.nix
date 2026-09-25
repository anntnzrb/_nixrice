{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOpt' mkOptEnabled';

  cfg = config.liberion.shells.tmux;
  cockpit = "${config.xdg.configHome}/tmux/scripts/cockpit-reset.sh";
in
{
  options.liberion.shells.tmux = {
    layouts.cockpit = {
      enable = mkOptEnabled';
      bind = mkOpt' lib.types.str "M";
    };
  };

  config = lib.mkMerge [
    {
      programs.tmux = {
        enable = true;

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
          set -g extended-keys on
          set -g extended-keys-format csi-u

          set -g status-style bg=default,fg=default
          set -g status-justify left
          set -g automatic-rename off
          set -g status-left '[#S] '
          set -g status-right ' '
          setw -g window-status-format '#I:#W#F'
          setw -g window-status-current-format '#[bold]#I:#W#F'

          bind '"' split-window -v -c '#{pane_current_path}'
          bind % split-window -h -c '#{pane_current_path}'
          bind c new-window -c '#{pane_current_path}'

          bind -N "Reload tmux configuration" R source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config reloaded!"
        '';
      };
    }

    (lib.mkIf cfg.layouts.cockpit.enable {
      xdg.configFile."tmux/scripts/cockpit-reset.sh" = {
        source = ./scripts/cockpit-reset.sh;
        executable = true;
      };

      programs.tmux.extraConfig = lib.mkAfter ''
        bind -N "Reset current window to cockpit layout" ${cfg.layouts.cockpit.bind} command-prompt -I "#W" -p "Project name" "run-shell '${cockpit} \"%%\" \"#{window_id}\" \"#{pane_current_path}\"'"
      '';
    })
  ];
}
