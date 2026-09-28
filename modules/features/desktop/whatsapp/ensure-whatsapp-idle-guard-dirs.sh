# shellcheck shell=sh

set -eu

state_dir=${1:?state_dir required}
log_dir=${2:?log_dir required}

mkdir -p "${state_dir}" "${log_dir}"
