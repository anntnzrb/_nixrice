# shellcheck shell=bash

set -euo pipefail

script=${1}
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

mkdir -p "${work}/bin"
{
    printf '#!%s\n' "${BASH}"
    cat <<'FAKE'
printf 'xcrun %s\n' "$*" >>"${CALLS}"
target=${4}
if [ "${2}" = validate ]; then
    if [[ " ${VALID:-} " == *" ${target} "* ]]; then
        exit 0
    fi
    exit 65
fi
if [[ " ${FAIL_STAPLE:-} " == *" ${target} "* ]]; then
    exit 1
fi
FAKE
} >"${work}/bin/xcrun"
{
    printf '#!%s\n' "${BASH}"
    cat <<'FAKE'
printf 'spctl %s\n' "$*" >>"${CALLS}"
target=${4}
if [[ " ${REJECT_ASSESSMENT:-} " == *" ${target} "* ]]; then
    exit 3
fi
FAKE
} >"${work}/bin/spctl"
{
    printf '#!%s\n' "${BASH}"
    cat <<'FAKE'
printf 'xattr %s\n' "$*" >>"${CALLS}"
case ${1} in
    -p)
        if [ -z "${QUARANTINE_VALUE:-}" ]; then
            exit 1
        fi
        printf '%s\n' "${QUARANTINE_VALUE}"
        ;;
    -rsw)
        if [[ " ${FAIL_WRITE:-} " == *" ${4} "* ]]; then
            exit 1
        fi
        ;;
esac
FAKE
} >"${work}/bin/xattr"
chmod +x "${work}/bin/xcrun" "${work}/bin/spctl" "${work}/bin/xattr"
export PATH="${work}/bin:${PATH}" CALLS="${work}/calls"

run_script() {
    bash -euo pipefail "${script}" "$@"
}

app="${work}/Tinycast.app"
helper="${app}/Contents/Helpers/Tinycast Dictation.app"
other="${work}/Other.app"
expected="${work}/expected"
mkdir -p "${helper}" "${other}"

run_script "${work}/Missing.app"
test ! -e "${CALLS}"
echo 'PASS missing app: no Gatekeeper calls'

: >"${CALLS}"
run_script "${app}"
cat >"${expected}" <<EOF_EXPECTED
xattr -p com.apple.quarantine ${app}
EOF_EXPECTED
cmp "${expected}" "${CALLS}"
echo 'PASS unquarantined app: left alone'

: >"${CALLS}"
QUARANTINE_VALUE='0181;6b06eef8;;event-id' run_script "${app}"
cat >"${expected}" <<EOF_EXPECTED
xattr -p com.apple.quarantine ${app}
xcrun stapler validate -q ${helper}
xcrun stapler staple -q ${helper}
xcrun stapler validate -q ${app}
xcrun stapler staple -q ${app}
spctl --assess --type execute ${app}
xattr -rsw com.apple.quarantine 01c1;6b06eef8;;event-id ${app}
EOF_EXPECTED
cmp "${expected}" "${CALLS}"
echo 'PASS unapproved app: staple, assess, then approve recursively'

: >"${CALLS}"
QUARANTINE_VALUE='01c1;6b06eef8;;event-id' run_script "${app}"
cat >"${expected}" <<EOF_EXPECTED
xattr -p com.apple.quarantine ${app}
EOF_EXPECTED
cmp "${expected}" "${CALLS}"
echo 'PASS approved app: no network or writes'

: >"${CALLS}"
QUARANTINE_VALUE='bogus;6b06eef8;;event-id' run_script "${app}" 2>"${work}/stderr"
grep -F "gatekeeper-approval: ${app} has malformed quarantine flags" "${work}/stderr" >/dev/null
cmp "${expected}" "${CALLS}"
echo 'PASS malformed quarantine: warns and leaves it unchanged'

: >"${CALLS}"
QUARANTINE_VALUE='0181;6b06eef8;;event-id' REJECT_ASSESSMENT="${app}" run_script "${app}" 2>"${work}/stderr"
grep -F "gatekeeper-approval: ${app} failed Gatekeeper assessment" "${work}/stderr" >/dev/null
if grep -F 'xattr -rsw' "${CALLS}" >/dev/null; then
    echo 'approval written despite failed assessment' >&2
    exit 1
fi
echo 'PASS rejected assessment: no approval write'

: >"${CALLS}"
QUARANTINE_VALUE='0181;6b06eef8;;event-id' REJECT_ASSESSMENT="${app}" run_script "${app}" "${other}" 2>/dev/null
grep -F "xattr -rsw com.apple.quarantine 01c1;6b06eef8;;event-id ${other}" "${CALLS}" >/dev/null
echo 'PASS rejected app does not block later apps'

: >"${CALLS}"
QUARANTINE_VALUE='0181;6b06eef8;;event-id' FAIL_WRITE="${app}" run_script "${app}" 2>"${work}/stderr"
grep -F "gatekeeper-approval: could not record approval for ${app}" "${work}/stderr" >/dev/null
echo 'PASS approval write failure: warns without aborting activation'

: >"${CALLS}"
QUARANTINE_VALUE='0181;6b06eef8;;event-id' FAIL_STAPLE="${app} ${helper}" run_script "${app}" 2>"${work}/stderr"
grep -F "xattr -rsw com.apple.quarantine 01c1;6b06eef8;;event-id ${app}" "${CALLS}" >/dev/null
grep -F "gatekeeper-approval: could not staple ${app}" "${work}/stderr" >/dev/null
echo 'PASS staple failure: warning only, Gatekeeper assessment still owns approval'
