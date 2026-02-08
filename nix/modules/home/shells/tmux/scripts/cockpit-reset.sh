#!/usr/bin/env bash
set -euo pipefail

project_name="${1-}"
window_id="${2-}"
working_directory="${3-}"

if [[ -z "${window_id}" ]]; then
    window_id="$(tmux display-message -p "#{window_id}")"
fi

if [[ -z "${working_directory}" ]]; then
    working_directory="$(tmux display-message -p -t "${window_id}" "#{pane_current_path}")"
fi

if [[ -z "${project_name}" ]]; then
    project_name="$(tmux display-message -p -t "${window_id}" "#W")"
fi

editor_command="${EDITOR:-nvim} ."

tmux rename-window -t "${window_id}" "${project_name}"

# Reset current window to one pane before rebuilding the cockpit.
tmux kill-pane -a -t "${window_id}"
tmux respawn-pane -k -t "${window_id}.1" -c "${working_directory}"

# Right column: top editor, bottom git TUI.
right_top_pane_id="$(
    tmux split-window \
        -d \
        -h \
        -t "${window_id}.1" \
        -c "${working_directory}" \
        -P \
        -F "#{pane_id}" \
        "${editor_command}"
)"

tmux split-window -d -v -t "${right_top_pane_id}" -c "${working_directory}" "lazygit"

# Left column: tiny scratch pane under the master pane.
tmux split-window -d -v -l 7 -t "${window_id}.1" -c "${working_directory}"

if ! tmux resize-pane -t "${window_id}.1" -x 70 -y 30; then
    tmux display-message "Cockpit resize skipped: window too small for 70x30"
fi

tmux select-pane -t "${window_id}.1"
