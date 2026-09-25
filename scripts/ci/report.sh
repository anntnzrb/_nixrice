#!/usr/bin/env sh
# Markdown summary of what the working tree changes in every machine and home
# versus a git ref (default: HEAD): packages, files, services, users, env...
# (fingerprint.nix). Prints nothing when no machine's behaviour changes.

set -eu

here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'git worktree remove --force "${tmp}/base" >/dev/null 2>&1 || true; rm -rf "${tmp}"' EXIT

git worktree add --detach --quiet "${tmp}/base" "${1:-HEAD}"

# one "<machine> <path> = <value>" line per leaf of the fingerprint of the
# flake in $1; list positions become [], newlines are escaped. Evaluation
# stderr (upstream deprecation traces) is shown only on failure.
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

# "-"/"+" per line, grouped by machine, at most 40 lines each
diff "${tmp}/before" "${tmp}/after" \
    | sed -n 's/^< /- /p; s/^> /+ /p' \
    | sort -s -k2,2 \
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
