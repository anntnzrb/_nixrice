# shellcheck shell=sh
# Sourced by scripts that hold temporary state (directories, git worktrees);
# the script defines a `cleanup` function first. It runs once when the script
# ends: normally, on error (set -e), or on Ctrl+C, kill or a dropped ssh
# session. POSIX leaves the EXIT trap on a signal death optional and dash
# (Ubuntu's sh) skips it, so the signals are trapped too; each handler then
# re-raises its signal, so a caller (just, a shell loop, CI) stops as well.

trap cleanup EXIT
for sig in HUP INT TERM; do
    # shellcheck disable=SC2064 # the signal name is fixed per handler
    trap "trap '' HUP INT TERM; cleanup; trap - EXIT ${sig}; kill -s ${sig} \$\$" "${sig}"
done
