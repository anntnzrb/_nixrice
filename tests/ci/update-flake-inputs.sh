#!/usr/bin/env sh
# shellcheck disable=SC2086,SC2250,SC2312

set -eu

# Fixture paths stay deliberately compact in this test harness.

source_root=$(git rev-parse --show-toplevel)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

make_fixture() {
    fixture=$1
    mkdir -p "$fixture/scripts/ci" "$fixture/bin"
    cp "$source_root/scripts/ci/update-flake-inputs.sh" "$fixture/scripts/ci/"
    cat >"$fixture/flake.lock" <<'JSON'
{"version":7,"root":"root","nodes":{"root":{"inputs":{"bad1":"bad1","bad2":"bad2","good":"good"}},"bad1":{"locked":{"rev":"old"}},"bad2":{"locked":{"rev":"old"}},"good":{"locked":{"rev":"old"}}}}
JSON
    printf '%s\n' "${scenario}" >"${fixture}/scenario"
    printf "#!/usr/bin/env bash\nset -euo pipefail\nscenario='%s'\n" "${scenario}" >"${fixture}/check"
    cat >>"$fixture/check" <<'SH'
case "$scenario" in
  total-failure) exit 1 ;;
  incompatible)
    [[ "$(jq -r .nodes.bad1.locked.rev flake.lock)" != new ]]
    [[ "$(jq -r .nodes.bad2.locked.rev flake.lock)" != new ]]
    ;;
esac
SH
    printf "#!/usr/bin/env bash\nset -euo pipefail\nscenario='%s'\n" "${scenario}" >"${fixture}/bin/nix"
    cat >>"$fixture/bin/nix" <<'SH'
shift 2
[[ "$scenario" != update-failure ]] || exit 1
[[ "$scenario" != up-to-date ]] || exit 0
for input in "$@"; do
  tmp="$(mktemp)"
  jq --arg input "$input" '.nodes[$input].locked.rev = "new"' flake.lock >"$tmp"
  mv "$tmp" flake.lock
done
SH
    cat >"$fixture/bin/timeout" <<'SH'
#!/usr/bin/env bash
shift
exec "$@"
SH
    chmod +x "$fixture/check" "$fixture/bin/nix" "$fixture/bin/timeout" "$fixture/scripts/ci/update-flake-inputs.sh"
    git -C "$fixture" init -q
    git -C "$fixture" config user.email ci@example.invalid
    git -C "$fixture" config user.name CI
    git -C "$fixture" add .
    git -C "$fixture" commit -qm fixture
}

run_case() {
    name=$1
    scenario=$2
    expected_status=$3
    max_attempts=${4:-9}
    requested=${5:-}
    fixture=${scratch}/${name}
    make_fixture "${fixture}"
    before=$(sha256sum "${fixture}/flake.lock" | cut -d ' ' -f 1)
    set +e
    output=$(cd "${fixture}" && PATH="${fixture}/bin:${PATH}" \
        UPDATE_FLAKE_CHECK="${fixture}/check" UPDATE_FLAKE_TIMEOUT=5 \
        UPDATE_FLAKE_MAX_ATTEMPTS="${max_attempts}" scripts/ci/update-flake-inputs.sh ${requested} 2>&1)
    status=$?
    set -e
    test "${status}" -eq "${expected_status}" || {
        printf '%s\n' "${output}"
        return 1
    }
    after=$(sha256sum "${fixture}/flake.lock" | cut -d ' ' -f 1)
    case "${name}" in
        full-success)
            printf '%s\n' "${output}" | grep -q '^changed=true$'
            jq -e '[.nodes.bad1,.nodes.bad2,.nodes.good] | all(.locked.rev == "new")' "${fixture}/flake.lock" >/dev/null
            ;;
        up-to-date)
            printf '%s\n' "${output}" | grep -q '^changed=false$'
            test "${before}" = "${after}"
            ;;
        incompatible)
            printf '%s\n' "${output}" | grep -q '^selected=good$'
            printf '%s\n' "${output}" | grep -q '^rejected=bad1 bad2$'
            jq -e '.nodes.good.locked.rev == "new"' "${fixture}/flake.lock" >/dev/null
            ;;
        selective)
            printf '%s\n' "${output}" | grep -q '^selected=good$'
            jq -e '.nodes.good.locked.rev == "new" and .nodes.bad1.locked.rev == "old" and .nodes.bad2.locked.rev == "old"' "${fixture}/flake.lock" >/dev/null
            ;;
        *) test "${before}" = "${after}" ;;
    esac
    printf 'ok - %s\n' "${name}"
}

run_case full-success success 0
run_case up-to-date up-to-date 0
run_case incompatible incompatible 0
run_case selective success 0 9 good
run_case total-failure total-failure 1
run_case update-failure update-failure 1
run_case budget-exhaustion total-failure 1 1
