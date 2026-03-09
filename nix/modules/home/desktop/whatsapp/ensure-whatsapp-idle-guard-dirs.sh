# Directory bootstrap for the WhatsApp idle guard.
#
# This is intentionally tiny because it runs during Home Manager activation,
# before launchd starts the agent. launchd opens stdout/stderr paths eagerly,
# so the log directory must already exist by the time the agent is loaded.
#
# Arguments:
# 1. state_dir
# 2. log_dir

set -eu

state_dir=${1:?state_dir required}
log_dir=${2:?log_dir required}

mkdir -p "$state_dir" "$log_dir"
