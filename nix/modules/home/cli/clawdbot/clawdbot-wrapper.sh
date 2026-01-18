# shellcheck shell=bash
set -euo pipefail

minimax_env="@minimaxApiKeyEnv@"
minimax_file="@minimaxKeyFile@"
if [ ! -f "$minimax_file" ]; then
    echo "MINIMAX API key file not found: $minimax_file" >&2
    exit 1
fi

minimax_key="$(/bin/cat "$minimax_file")"
if [ -z "$minimax_key" ]; then
    echo "MINIMAX API key file is empty: $minimax_file" >&2
    exit 1
fi

export "${minimax_env}=${minimax_key}"
exec clawdbot "$@"
