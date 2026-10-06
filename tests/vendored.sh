# shellcheck shell=bash

set -euo pipefail

updater=$1
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
export HOME="${work}/home" XDG_CACHE_HOME="${work}/cache" GIT_CONFIG_NOSYSTEM=1
unset GIT_CONFIG_GLOBAL
root="${HOME}/src/vendored"
mkdir -p "${HOME}"
"${updater}" "${root}"
test -d "${root}"

source_repo="${work}/source"
git init --quiet --initial-branch=main "${source_repo}"
git -C "${source_repo}" config user.name Test
git -C "${source_repo}" config user.email test@example.invalid
printf '%s\n' old >"${source_repo}/source.txt"
printf '%s\n' removed >"${source_repo}/removed.txt"
printf '%s\n' ignored >"${source_repo}/.gitignore"
mkdir "${source_repo}/library"
printf '%s\n' source >"${source_repo}/library/reference.txt"
git -C "${source_repo}" add .
git -C "${source_repo}" commit --quiet -m old
old_commit=$(git -C "${source_repo}" rev-parse HEAD)
old_blob=$(git -C "${source_repo}" rev-parse HEAD:removed.txt)
git -C "${source_repo}" tag old
git -C "${source_repo}" branch legacy
remote="${work}/remote.git"
git clone --quiet --bare "${source_repo}" "${remote}"
git -C "${remote}" config uploadpack.allowFilter true
git -C "${source_repo}" remote add origin "file://${remote}"

normal="${root}/github.com/owner/nested namespace/normal repo"
partial="${root}/flat-partial"
sparse="${root}/github.com/owner/sparse"
git clone --quiet "file://${remote}" "${normal}"
git clone --quiet --depth=1 --filter=blob:none --no-tags "file://${remote}" "${partial}"
git clone --quiet --depth=1 --filter=blob:none --sparse --no-tags "file://${remote}" "${sparse}"
test ! -e "${sparse}/library/reference.txt"
markers=$(find "${partial}/.git/objects/pack" -name '*.promisor' -print)
test -n "${markers}"
git -C "${normal}" config user.name Test
git -C "${normal}" config user.email test@example.invalid
printf '%s\n' stash >"${normal}/source.txt"
git -C "${normal}" stash push --quiet
printf '%s\n' dirty >"${normal}/source.txt"
printf '%s\n' junk >"${normal}/ignored"
printf '%s\n' junk >"${normal}/untracked"
git init --quiet "${normal}/nested-repo"

printf '%s\n' current >"${source_repo}/source.txt"
git -C "${source_repo}" rm --quiet removed.txt
git -C "${source_repo}" add .
git -C "${source_repo}" commit --quiet -m current
git -C "${source_repo}" push --quiet origin main
current_commit=$(git -C "${source_repo}" rev-parse HEAD)
"${updater}" "${root}"

assert_current() {
    checkout=$1
    content=$(cat "${checkout}/source.txt")
    test "${content}" = current
    test ! -e "${checkout}/removed.txt"
    commit=$(git -C "${checkout}" rev-parse HEAD)
    test "${commit}" = "${current_commit}"
    count=$(git -C "${checkout}" rev-list --count HEAD)
    test "${count}" = 1
    refs=$(git -C "${checkout}" for-each-ref)
    test -z "${refs}"
    reflogs=$(git -C "${checkout}" reflog --all)
    test -z "${reflogs}"
    if git -C "${checkout}" cat-file -e "${old_commit}" 2>/dev/null; then
        printf '%s\n' 'old commit still stored' >&2
        exit 1
    fi
    if git -C "${checkout}" cat-file -e "${old_blob}" 2>/dev/null; then
        printf '%s\n' 'old blob still stored' >&2
        exit 1
    fi
    git -C "${checkout}" rev-list --objects --no-object-names HEAD | sort >"${work}/reachable"
    git -C "${checkout}" cat-file --batch-all-objects --batch-check='%(objectname)' | sort >"${work}/stored"
    cmp "${work}/reachable" "${work}/stored"
}
assert_current "${normal}"
assert_current "${partial}"
assert_current "${sparse}"
content=$(cat "${sparse}/library/reference.txt")
test "${content}" = source
test ! -e "${normal}/ignored"
test ! -e "${normal}/untracked"
test ! -e "${normal}/nested-repo"
markers=$(find "${partial}/.git/objects/pack" -name '*.promisor' -print)
test -z "${markers}"
if git -C "${partial}" config --get remote.origin.promisor; then
    exit 1
fi
"${updater}" "${root}"
assert_current "${normal}"
assert_current "${partial}"
assert_current "${sparse}"

git -C "${source_repo}" checkout --quiet --orphan replacement
git -C "${source_repo}" rm --quiet -rf .
printf '%s\n' current >"${source_repo}/source.txt"
git -C "${source_repo}" add .
git -C "${source_repo}" commit --quiet -m replacement
git -C "${source_repo}" push --quiet origin replacement
git -C "${remote}" symbolic-ref HEAD refs/heads/replacement
current_commit=$(git -C "${source_repo}" rev-parse HEAD)
"${updater}" "${root}"
assert_current "${normal}"
assert_current "${partial}"

printf '%s\n' dirty >"${normal}/source.txt"
exec 8>"${XDG_CACHE_HOME}/vendored-update.lock"
flock -n 8
"${updater}" "${root}"
content=$(cat "${normal}/source.txt")
test "${content}" = dirty
flock -u 8
exec 8>&-

broken="${root}/a-broken"
git clone --quiet "file://${remote}" "${broken}"
git -C "${broken}" remote set-url origin "file://${work}/missing.git"
printf '%s\n' keep >"${broken}/untracked"
printf '%s\n' newer >"${source_repo}/source.txt"
git -C "${source_repo}" commit --quiet -am newer
git -C "${source_repo}" push --quiet origin replacement
if "${updater}" "${root}"; then
    printf '%s\n' 'failed remote reported success' >&2
    exit 1
fi
content=$(cat "${broken}/untracked")
test "${content}" = keep
commit=$(git -C "${broken}" rev-parse HEAD)
test "${commit}" = "${current_commit}"
content=$(cat "${normal}/source.txt")
test "${content}" = newer
content=$(cat "${partial}/source.txt")
test "${content}" = newer

external="${work}/external"
git clone --quiet "file://${remote}" "${external}"
mkdir "${root}/external-link"
ln -s "${external}/.git" "${root}/external-link/.git"
if "${updater}" "${root}"; then
    exit 1
fi
branch=$(git -C "${external}" symbolic-ref HEAD)
test -n "${branch}"
printf '%s\n' 'vendored updater tests passed'
