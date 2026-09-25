#!/bin/sh
set -eu

project_name="${1-}"
window_id="${2-}"
working_directory="${3-}"

[ -z "${window_id}" ] && window_id="$(tmux display-message -p "#{window_id}")"

[ -z "${working_directory}" ] \
    && working_directory="$(tmux display-message -p -t "${window_id}" "#{pane_current_path}")"

[ -z "${project_name}" ] && project_name="$(tmux display-message -p -t "${window_id}" "#W")"

editor_command="${EDITOR:-nvim} ."

# Layout profile derived from a single base unit.
# Default math preserves existing geometry: 70x30 master, 7-row scratch.
layout_unit_size="${TMUX_COCKPIT_LAYOUT_UNIT_SIZE:-10}"
master_width_units="${TMUX_COCKPIT_MASTER_WIDTH_UNITS:-7}"
master_height_units="${TMUX_COCKPIT_MASTER_HEIGHT_UNITS:-3}"
scratch_height_divisor="${TMUX_COCKPIT_SCRATCH_HEIGHT_DIVISOR:-4}"

target_master_width_columns=$((layout_unit_size * master_width_units))
target_master_height_rows=$((layout_unit_size * master_height_units))
target_scratch_height_rows=$((target_master_height_rows / scratch_height_divisor))

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
tmux split-window -d -v -l "${target_scratch_height_rows}" -t "${window_id}.1" -c "${working_directory}"

tmux resize-pane -t "${window_id}.1" -x "${target_master_width_columns}" -y "${target_master_height_rows}" \
    || tmux display-message "Cockpit resize skipped: window too small for ${target_master_width_columns}x${target_master_height_rows}"

tmux select-pane -t "${window_id}.1"
