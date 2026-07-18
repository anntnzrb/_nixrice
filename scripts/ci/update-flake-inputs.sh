#!/usr/bin/env sh
# shellcheck disable=SC2094,SC2310,SC2312

set -eu

# The selector handles attempt failures explicitly and intentionally appends to
# its queue while reading it.

root=$(git rev-parse --show-toplevel)
check=${UPDATE_FLAKE_CHECK:-"${root}/scripts/ci/check-flake.sh"}
attempt_timeout=${UPDATE_FLAKE_TIMEOUT:-3600}
cd "${root}"
git diff --quiet --exit-code
git diff --cached --quiet --exit-code
test -z "$(git ls-files --others --exclude-standard)"

all_inputs=$(jq -r '.nodes[.root].inputs | keys[]' flake.lock | LC_ALL=C sort)
if test "$#" -eq 0; then
    inputs=${all_inputs}
else
    inputs=$(printf '%s\n' "$@" | LC_ALL=C sort -u)
    for input in ${inputs}; do
        if ! printf '%s\n' "${all_inputs}" | grep -Fxq "${input}"; then
            printf 'Unknown root input: %s\n' "${input}" >&2
            exit 2
        fi
    done
fi
input_count=$(printf '%s\n' "${inputs}" | awk 'NF { count++ } END { print count + 0 }')
max_attempts=${UPDATE_FLAKE_MAX_ATTEMPTS:-$((3 * input_count))}
scratch=$(mktemp -d)
selected_lock=${scratch}/selected.lock
cp flake.lock "${selected_lock}"

attempts=0
attempt_result=
candidate_lock=
selected=
rejected=

cleanup() {
    git worktree prune >/dev/null 2>&1 || true
    rm -rf "${scratch}"
}
trap cleanup EXIT HUP INT TERM

emit() {
    changed=$1
    selected=${selected# }
    rejected=${rejected# }
    printf 'changed=%s\nselected=%s\nrejected=%s\nattempts=%s\n' \
        "${changed}" "${selected}" "${rejected}" "${attempts}"
    if test -n "${GITHUB_OUTPUT:-}"; then
        printf 'changed=%s\nselected=%s\nrejected=%s\nattempts=%s\n' \
            "${changed}" "${selected}" "${rejected}" "${attempts}" >>"${GITHUB_OUTPUT}"
    fi
}

try_group() {
    worktree=${scratch}/worktree-${attempts}
    if test "${attempts}" -ge "${max_attempts}"; then
        attempt_result=budget
        return 1
    fi
    attempts=$((attempts + 1))
    git worktree add --quiet --detach "${worktree}" HEAD
    cp "${selected_lock}" "${worktree}/flake.lock"

    if ! (
        cd "${worktree}" \
            && timeout "${attempt_timeout}" nix flake update "$@" \
            && timeout "${attempt_timeout}" "${check}" \
            && git diff --quiet --exit-code -- . ':(exclude)flake.lock'
    ); then
        attempt_result=failed
        git worktree remove --force "${worktree}"
        return 1
    fi

    if cmp -s "${selected_lock}" "${worktree}/flake.lock"; then
        attempt_result=unchanged
    else
        candidate_lock=${scratch}/candidate-${attempts}.lock
        cp "${worktree}/flake.lock" "${candidate_lock}"
        attempt_result=changed
    fi
    git worktree remove --force "${worktree}"
}

if test "${input_count}" -eq 0; then
    emit false
    exit 0
fi

# shellcheck disable=SC2086
if try_group ${inputs}; then
    if test "${attempt_result}" = changed; then
        cp "${candidate_lock}" flake.lock
        selected=$(printf '%s' "${inputs}" | tr '\n' ' ' | sed 's/ $//')
        emit true
    else
        emit false
    fi
    exit 0
fi

printf '%s\n' "$(printf '%s' "${inputs}" | tr '\n' ' ')" >"${scratch}/queue"
while IFS= read -r group; do
    test -n "${group}" || continue
    # shellcheck disable=SC2086
    if try_group ${group}; then
        if test "${attempt_result}" = changed; then
            cp "${candidate_lock}" "${selected_lock}"
            selected="${selected} ${group}"
        fi
    elif test "${attempt_result}" = budget; then
        emit false
        exit 1
    else
        set -- ${group}
        if test "$#" -eq 1; then
            rejected="${rejected} $1"
        else
            middle=$(($# / 2))
            printf '%s\n' "${group}" | awk -v middle="${middle}" '{ for (i=1;i<=middle;i++) printf "%s%s", $i, (i==middle?ORS:OFS); for (i=middle+1;i<=NF;i++) printf "%s%s", $i, (i==NF?ORS:OFS) }' >>"${scratch}/queue"
        fi
    fi
done <"${scratch}/queue"

retry=${rejected# }
rejected=
for input in ${retry}; do
    if try_group "${input}"; then
        if test "${attempt_result}" = changed; then
            cp "${candidate_lock}" "${selected_lock}"
            selected="${selected} ${input}"
        fi
    elif test "${attempt_result}" = budget; then
        emit false
        exit 1
    else
        rejected="${rejected} ${input}"
    fi
done

if cmp -s flake.lock "${selected_lock}"; then
    emit false
    exit 1
fi
cp "${selected_lock}" flake.lock
emit true
