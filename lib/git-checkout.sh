#!/bin/sh
set -eu

repository=$1
destination=$2
branch=$3
update=${4:-}

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=15'

if [ ! -e "${destination}" ] && [ ! -L "${destination}" ]; then
    parent=$(dirname "${destination}")
    mkdir -p "${parent}"
    temporary=$(mktemp -d "${parent}/.git-clone.XXXXXXXX")
    trap 'rm -rf "${temporary}"' EXIT
    trap 'exit 1' HUP INT TERM
    git clone --branch "${branch}" --single-branch "${repository}" "${temporary}/repository"
    if [ -e "${destination}" ] || [ -L "${destination}" ]; then
        echo "git-checkout: destination appeared during clone; refusing to replace it" >&2
        exit 1
    fi
    mv "${temporary}/repository" "${destination}"
    rmdir "${temporary}"
    trap - EXIT
    if [ -z "${update}" ]; then
        exit 0
    fi
fi

if [ -L "${destination}" ] || [ ! -d "${destination}/.git" ]; then
    echo "git-checkout: destination is not an owned Git checkout: ${destination}" >&2
    exit 1
fi
origin=$(git -C "${destination}" remote get-url origin)
if [ "${origin}" != "${repository}" ]; then
    echo "git-checkout: unexpected origin; leaving checkout untouched" >&2
    exit 1
fi
if [ -n "${update}" ]; then
    exec "${update}" "${destination}"
fi
current=$(git -C "${destination}" symbolic-ref --quiet --short HEAD) || exit 0
if [ "${current}" != "${branch}" ]; then
    echo "git-checkout: working branch; skipping update"
    exit 0
fi
changes=$(git -C "${destination}" status --porcelain --untracked-files=normal)
if [ -n "${changes}" ]; then
    echo "git-checkout: local changes; skipping update"
    exit 0
fi

git -C "${destination}" fetch --no-tags origin "${branch}"
git -C "${destination}" merge --ff-only FETCH_HEAD
