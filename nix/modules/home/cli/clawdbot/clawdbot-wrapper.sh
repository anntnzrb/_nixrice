# shellcheck shell=bash
set -euo pipefail

provider_env="@providerApiKeyEnv@"
provider_key_file="@providerApiKeyFile@"
if [ ! -f "$provider_key_file" ]; then
    echo "API key file not found: $provider_key_file" >&2
    exit 1
fi

provider_key="$(/bin/cat "$provider_key_file")"
if [ -z "$provider_key" ]; then
    echo "API key file is empty: $provider_key_file" >&2
    exit 1
fi

export "${provider_env}=${provider_key}"
exec clawdbot "$@"
