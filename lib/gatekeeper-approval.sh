# shellcheck shell=sh

# WebKit QTN_FLAG_USER_APPROVED, also used by Homebrew when inheriting approval.
user_approved=0x40

staple() {
    target=${1}

    if xcrun stapler validate -q "${target}" >/dev/null 2>&1; then
        return 0
    fi

    if ! xcrun stapler staple -q "${target}" >/dev/null 2>&1; then
        echo >&2 "gatekeeper-approval: could not staple ${target}; Gatekeeper may need the network for assessment"
    fi
}

staple_app() {
    app=${1}

    if [ -d "${app}/Contents" ]; then
        find "${app}/Contents" -depth -type d -name '*.app' -print \
            | while IFS= read -r helper; do
                staple "${helper}"
            done
    fi

    staple "${app}"
}

approve_app() {
    app=${1}

    [ -d "${app}" ] || return 0

    if ! quarantine=$(xattr -p com.apple.quarantine "${app}" 2>/dev/null); then
        return 0
    fi

    flags=${quarantine%%;*}
    case ${flags} in
        '' | *[!0-9a-fA-F]*)
            echo >&2 "gatekeeper-approval: ${app} has malformed quarantine flags; leaving them unchanged"
            return 0
            ;;
        *) ;;
    esac

    if [ $((0x${flags} & user_approved)) -ne 0 ]; then
        return 0
    fi

    staple_app "${app}"

    if ! spctl --assess --type execute "${app}" >/dev/null 2>&1; then
        echo >&2 "gatekeeper-approval: ${app} failed Gatekeeper assessment; leaving quarantine unapproved"
        return 0
    fi

    rest=${quarantine#"${flags}"}
    approved_flags=$(printf '%0*x' "${#flags}" $((0x${flags} | user_approved)))
    if ! xattr -rsw com.apple.quarantine "${approved_flags}${rest}" "${app}" 2>/dev/null; then
        echo >&2 "gatekeeper-approval: could not record approval for ${app}; will retry on the next switch"
    fi
}

for app in "$@"; do
    approve_app "${app}"
done
