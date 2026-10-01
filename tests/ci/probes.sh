#!/usr/bin/env sh

set -eu

root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
cleanup() { rm -rf "${tmp}"; }
# shellcheck source=scripts/ci/cleanup.sh
. "${root}/scripts/ci/cleanup.sh"

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

assert_files_equal() {
    if ! cmp -s "$1" "$2"; then
        diff -u "$1" "$2" >&2 || true
        fail "files differ: $1 $2"
    fi
}

assert_log_has() {
    grep -Fx "$1" "${MOCK_LOG}" >/dev/null || fail "mock did not receive $1"
}

assert_failure_without_evaluation() {
    calls_before="$(wc -l <"${MOCK_CALLS}" | tr -d '[:space:]')"
    if "$@" >"${tmp}/invalid.out" 2>&1; then
        fail "command unexpectedly accepted an invalid target"
    fi
    calls_after="$(wc -l <"${MOCK_CALLS}" | tr -d '[:space:]')"
    [ "${calls_before}" = "${calls_after}" ] || fail "invalid target reached nix-eval-jobs"
}

mkdir -p "${tmp}/bin"
cat >"${tmp}/bin/nix-eval-jobs" <<'EOF'
#!/usr/bin/env sh

set -eu

workers=
memory=
expr=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --workers)
            workers="$2"
            shift 2
            ;;
        --max-memory-size)
            memory="$2"
            shift 2
            ;;
        --expr)
            expr="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

printf 'call\n' >>"${MOCK_CALLS}"
printf 'workers=%s\nmemory=%s\nexpr=%s\n' "${workers}" "${memory}" "${expr}" >>"${MOCK_LOG}"

if [ "${MOCK_MODE:-}" = evaluator-failure ]; then
    exit 23
fi

emit_nixos() {
    printf '%s\n' \
        '{"attr":"nixos-probe.alpha","drvPath":"/nix/store/nixos-alpha.drv"}' \
        '{"attr":"nixos-probe.omega","drvPath":"/nix/store/nixos-omega.drv"}'
}

emit_darwin() {
    printf '%s\n' \
        '{"attr":"darwin-probe.beta","drvPath":"/nix/store/darwin-beta.drv"}' \
        '{"attr":"darwin-probe.delta","drvPath":"/nix/store/darwin-delta.drv"}'
}

emit_home() {
    if [ "${MOCK_MODE:-}" = missing-expected-error ]; then
        printf '%s\n' '{"attr":"home-probe.whatsapp","drvPath":"/nix/store/home-whatsapp.drv"}'
    else
        printf '%s\n' '{"attr":"home-probe.whatsapp","error":"expected home error"}'
    fi
    printf '%s\n' '{"attr":"home-probe.zulu","drvPath":"/nix/store/home-zulu.drv"}'
    if [ "${MOCK_MODE:-}" = unexpected-error ]; then
        printf '%s\n' '{"attr":"home-probe.unexpected","error":"unexpected error"}'
    fi
}

emit_home_darwin() {
    printf '%s\n' \
        '{"attr":"home-darwin-probe.chromium","error":"expected darwin home error"}' \
        '{"attr":"home-darwin-probe.xterm","drvPath":"/nix/store/home-darwin-xterm.drv"}'
}

case "${expr}" in
    *home-darwin-probe*) emit_home_darwin ;;
    *home-probe*) emit_home ;;
    *darwin-probe*) emit_darwin ;;
    *nixos-probe*) emit_nixos ;;
    *)
        emit_nixos
        emit_darwin
        emit_home
        emit_home_darwin
        ;;
esac
EOF
chmod +x "${tmp}/bin/nix-eval-jobs"

export PATH="${tmp}/bin:${PATH}"
export MOCK_LOG="${tmp}/mock.log"
export MOCK_CALLS="${tmp}/mock.calls"
export MOCK_MODE=
: >"${MOCK_LOG}"
: >"${MOCK_CALLS}"

cat >"${tmp}/expected-all" <<'EOF'
probe.darwin-probe.beta /nix/store/darwin-beta.drv
probe.darwin-probe.delta /nix/store/darwin-delta.drv
probe.home-darwin-probe.chromium eval-error
probe.home-darwin-probe.xterm /nix/store/home-darwin-xterm.drv
probe.home-probe.whatsapp eval-error
probe.home-probe.zulu /nix/store/home-zulu.drv
probe.nixos-probe.alpha /nix/store/nixos-alpha.drv
probe.nixos-probe.omega /nix/store/nixos-omega.drv
EOF
cat >"${tmp}/expected-nixos" <<'EOF'
probe.nixos-probe.alpha /nix/store/nixos-alpha.drv
probe.nixos-probe.omega /nix/store/nixos-omega.drv
EOF
cat >"${tmp}/expected-darwin" <<'EOF'
probe.darwin-probe.beta /nix/store/darwin-beta.drv
probe.darwin-probe.delta /nix/store/darwin-delta.drv
EOF
cat >"${tmp}/expected-home" <<'EOF'
probe.home-probe.whatsapp eval-error
probe.home-probe.zulu /nix/store/home-zulu.drv
EOF
cat >"${tmp}/expected-home-darwin" <<'EOF'
probe.home-darwin-probe.chromium eval-error
probe.home-darwin-probe.xterm /nix/store/home-darwin-xterm.drv
EOF

unset PROBE_WORKERS PROBE_MAX_MEMORY
default_workers="$(getconf NPROCESSORS_ONLN 2>/dev/null || getconf _NPROCESSORS_ONLN)"
"${root}/scripts/ci/probe.sh" "${root}" >"${tmp}/defaults"
assert_files_equal "${tmp}/expected-all" "${tmp}/defaults"
assert_log_has "workers=${default_workers}"
assert_log_has 'memory=2048'

export PROBE_WORKERS=7
export PROBE_MAX_MEMORY=1234

"${root}/scripts/ci/probe.sh" "${root}" >"${tmp}/all"
assert_files_equal "${tmp}/expected-all" "${tmp}/all"
"${root}/scripts/ci/probe.sh" "${root}" '' >"${tmp}/empty-target"
assert_files_equal "${tmp}/expected-all" "${tmp}/empty-target"

"${root}/scripts/ci/probe.sh" "${root}" nixos-probe >"${tmp}/nixos"
assert_files_equal "${tmp}/expected-nixos" "${tmp}/nixos"
"${root}/scripts/ci/probe.sh" "${root}" darwin-probe >"${tmp}/darwin"
assert_files_equal "${tmp}/expected-darwin" "${tmp}/darwin"
"${root}/scripts/ci/probe.sh" "${root}" home-probe >"${tmp}/home"
assert_files_equal "${tmp}/expected-home" "${tmp}/home"
"${root}/scripts/ci/probe.sh" "${root}" home-darwin-probe >"${tmp}/home-darwin"
assert_files_equal "${tmp}/expected-home-darwin" "${tmp}/home-darwin"
cat "${tmp}/nixos" "${tmp}/darwin" "${tmp}/home" "${tmp}/home-darwin" | sort >"${tmp}/concatenated"
assert_files_equal "${tmp}/expected-all" "${tmp}/concatenated"
assert_files_equal "${tmp}/all" "${tmp}/concatenated"
assert_log_has 'workers=7'
assert_log_has 'memory=1234'

"${root}/scripts/ci/check-probes.sh" "${root}" home-probe >"${tmp}/check-home"
"${root}/scripts/ci/check-probes.sh" "${root}" home-darwin-probe >"${tmp}/check-home-darwin"
"${root}/scripts/ci/check-probes.sh" "${root}" >"${tmp}/check-all"

MOCK_MODE=unexpected-error
export MOCK_MODE
if "${root}/scripts/ci/check-probes.sh" "${root}" home-probe >"${tmp}/unexpected.out" 2>&1; then
    fail "check-probes accepted an unexpected evaluation error"
fi

MOCK_MODE=missing-expected-error
export MOCK_MODE
if "${root}/scripts/ci/check-probes.sh" "${root}" home-probe >"${tmp}/missing.out" 2>&1; then
    fail "check-probes accepted a disappeared expected evaluation error"
fi

MOCK_MODE=evaluator-failure
export MOCK_MODE
if "${root}/scripts/ci/check-probes.sh" "${root}" home-probe >"${tmp}/evaluator-failure.out" 2>&1; then
    fail "check-probes swallowed an evaluator failure"
else
    status=$?
    [ "${status}" -eq 23 ] || fail "check-probes returned ${status}, expected evaluator status 23"
fi

MOCK_MODE=
export MOCK_MODE
assert_failure_without_evaluation "${root}/scripts/ci/probe.sh" "${root}" 'nixos-probe; touch /tmp/probe-target-accepted'
assert_failure_without_evaluation "${root}/scripts/ci/check-probes.sh" "${root}" 'nixos-probe; touch /tmp/probe-target-accepted'

printf '%s\n' 'probe sharding behavioral tests passed'
