#!/usr/bin/env sh

set -eu

target="${2:-}"
if [ -n "${target}" ]; then
    case "${target}" in
        nixos-probe | darwin-probe | home-probe | home-darwin-probe) ;;
        *)
            printf 'unknown probe target: %s\n' "${target}" >&2
            exit 2
            ;;
    esac
fi

flake="path:$(cd "${1:-.}" && pwd -P)"
probes="$(cd "$(dirname "$0")" && pwd)/probes.nix"
workers="${PROBE_WORKERS:-$(getconf NPROCESSORS_ONLN 2>/dev/null || getconf _NPROCESSORS_ONLN)}"
max_memory="${PROBE_MAX_MEMORY:-2048}"

eval_jobs() {
    if command -v nix-eval-jobs >/dev/null 2>&1; then
        nix-eval-jobs "$@"
    else
        nix run --option eval-cache false --no-write-lock-file \
            --inputs-from "${flake}" nixpkgs#nix-eval-jobs -- "$@"
    fi
}

expr="import ${probes} { flake = \"${flake}\"; }"
if [ -n "${target}" ]; then
    target_expr="$(jq -n --arg target "${target}" '$target')"
    expr="import ${probes} { flake = \"${flake}\"; target = ${target_expr}; }"
fi

out="$(eval_jobs \
    --workers "${workers}" \
    --max-memory-size "${max_memory}" \
    --force-recurse \
    --impure \
    --expr "${expr}")"

rows="$(printf '%s\n' "${out}" \
    | jq -r '
        if has("error") then
            "probe.\(.attr) eval-error"
        elif has("drvPath") then
            "probe.\(.attr) \(.drvPath)"
        else
            empty
        end
    ')"
printf '%s\n' "${rows}" | sort
