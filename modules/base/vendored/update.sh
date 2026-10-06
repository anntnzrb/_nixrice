# shellcheck shell=bash

self=$(readlink -f -- "${0}")

update_repo() {
    repo=$1
    work=$(mktemp -d)
    trap 'rm -rf "${work}"' EXIT
    trap 'exit 1' HUP INT TERM
    if test -L "${repo}/.git"; then
        printf 'vendored-update: refusing external Git directory: %s\n' "${repo}" >&2
        exit 1
    fi
    cd "${repo}" || exit
    git remote get-url origin >/dev/null
    git fetch --quiet --depth=1 --no-tags --no-filter --refmap= \
        --no-recurse-submodules --no-auto-maintenance origin HEAD
    git checkout --quiet --detach --force FETCH_HEAD
    if sparse=$(git config --bool --get core.sparseCheckout); then
        if test "${sparse}" = true; then
            git sparse-checkout disable
        fi
    else
        status=$?
        test "${status}" -eq 1 || exit "${status}"
    fi
    git clean -ffdx --quiet
    git for-each-ref --format='delete %(refname)' >"${work}/refs"
    git update-ref --no-deref --stdin <"${work}/refs"
    git update-ref --no-deref -d ORIG_HEAD
    git reflog expire --expire=now --all
    GIT_NO_LAZY_FETCH=1 git rev-list --objects --missing=error HEAD >/dev/null

    # Promisor packs keep unreachable objects; HEAD must be complete before removing these markers.
    find .git/objects/pack -type f -name '*.promisor' -delete
    if git config --local --name-only --get-regexp \
        '^remote\..*\.(promisor|partialclonefilter)$|^extensions\.partialclone$' >"${work}/config"; then
        while IFS= read -r key; do
            git config --local --unset-all "${key}"
        done <"${work}/config"
    else
        status=$?
        test "${status}" -eq 1 || exit "${status}"
    fi
    git repack -ad --quiet
    git prune --expire=now
    printf 'vendored-update: updated %s\n' "${repo}"
}

case ${1:-} in
    --worker)
        update_repo "${2}"
        exit
        ;;
    --repo)
        if timeout --kill-after=30s 300 "${self}" --worker "${2}"; then
            exit 0
        else
            status=$?
            printf 'vendored-update: failed %s (exit %s)\n' "${2}" "${status}" >&2
            exit 1
        fi
        ;;
    *) ;;
esac

root=${1:?usage: vendored-update ROOT}
cache=${XDG_CACHE_HOME:-${HOME}/.cache}
mkdir -p "${root}" "${cache}"
exec 9>"${cache}/vendored-update.lock"
if ! flock -n 9; then
    printf '%s\n' 'vendored-update: another update is running'
    exit 0
fi

export GIT_TERMINAL_PROMPT=0 GIT_LFS_SKIP_SMUDGE=1
export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=15'
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pack.threads GIT_CONFIG_VALUE_0=1

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
trap 'exit 1' HUP INT TERM
find "${root}" -type d -exec test -d '{}/.git' \; -prune -print0 >"${work}/repos"
xargs -0 -r -P 2 -n 1 "${self}" --repo <"${work}/repos"
