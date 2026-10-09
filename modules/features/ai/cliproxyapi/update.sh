#!/bin/sh

set -eu

account=$1
releases=$2
release=$3
configure=$4
settings=$5
models_cache=$6
runtime_config=$7
secrets=$8

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
