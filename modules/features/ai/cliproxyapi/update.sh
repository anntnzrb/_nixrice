#!/bin/sh

set -eu

account=${CPA_ACCOUNT:?}
releases=${CPA_RELEASES:?}
release=${CPA_RELEASE:?}
configure=${CPA_CONFIGURE:?}
settings=${CPA_SETTINGS:?}
models_cache=${CPA_MODELS_CACHE:?}
runtime_config=${CPA_RUNTIME_CONFIG:?}
secrets=${CPA_SECRETS:?}

runuser -u "${account}" -- "${release}" install --state "${releases}" --version latest
runtime_dir=$(dirname "${runtime_config}")
if [ -d "${runtime_dir}" ]; then
    runuser -u "${account}" -- "${configure}" --settings "${settings}" --models-cache "${models_cache}" --secrets "${secrets}" --out "${runtime_config}"
else
    runuser -u "${account}" -- "${configure}" --settings "${settings}" --models-cache "${models_cache}" --secrets "${secrets}"
fi
pid=$(systemctl show cliproxyapi.service --property MainPID --value)
if [ "${pid}" != 0 ]; then
    running=$(readlink "/proc/${pid}/exe" || true)
    selected=$(readlink -f "${releases}/current/cli-proxy-api")
    if [ "${running}" != "${selected}" ]; then
        systemctl try-restart cliproxyapi.service
    fi
fi
