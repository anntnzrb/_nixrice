# shellcheck shell=sh

trap cleanup EXIT
for sig in HUP INT TERM; do
    # shellcheck disable=SC2064 # the signal name is fixed per handler
    trap "trap '' HUP INT TERM; cleanup; trap - EXIT ${sig}; kill -s ${sig} \$\$" "${sig}"
done
