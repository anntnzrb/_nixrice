#!/usr/bin/env sh

set -eu

# shellcheck source=scripts/ci/worktree.sh
. "$(dirname "$0")/worktree.sh"

flat() {
    nix eval --impure --json \
        --expr "import ${here}/fingerprint.nix { flake = \"path:$1\"; }" \
        >"${tmp}/fp.json" 2>"${tmp}/fp.err" || {
        cat "${tmp}/fp.err" >&2
        exit 1
    }
    jq -r 'paths(scalars) as $p
        | [$p[0], ($p[1:] | map(if type == "number" then "[]" else tostring end) | join(".")),
           (getpath($p) | tostring | gsub("\n"; "\\n"))]
        | "\(.[0]) \(.[1]) = \(.[2])"' "${tmp}/fp.json" | sort -u
}

flat "${tmp}/base" >"${tmp}/before"
flat "${PWD}" >"${tmp}/after"

diff "${tmp}/before" "${tmp}/after" \
    | sed -n 's/^< /- /p; s/^> /+ /p' \
    | awk '{ print $2, NR, $0 }' \
    | sort -k1,1 -k2,2n \
    | cut -d ' ' -f 3- \
    | awk '
        {
            sign = $1; machine = $2; $1 = ""; $2 = ""; sub(/^  /, "")
            if (machine != last) {
                if (hidden) printf "- ... and %d more\n", hidden
                printf "\n### %s\n\n", machine; last = machine; shown = 0; hidden = 0
            }
            if (shown++ < 40) printf "- `%s %s`\n", sign, $0; else hidden++
        }
        END { if (hidden) printf "- ... and %d more\n", hidden }'
