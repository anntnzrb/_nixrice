# liberion - Utility app for managing Nix & NixOS-related operations.

# Commentary:

# This tool is meant to be used as a wrapper for some common Nix & NixOS commands.
# Originally created to drop the need for a Makefile in the project; which I personally
# find to be a bit overkill for such a smallset of operations.

# Code:

PROGRAM_NAME='liberion'

println() {
    ## Print a message to stdout. With a newline.

    printf '%s\n' "${@}"
}

die() {
    ## Print a message to stderr. With a newline. Then exit with a non-zero
    ## status.

    println "${@}" >&2

    exit 1
}

set_cmd_rebuild() {
    ## Set the command to use for rebuilding the system configuration.

    case "${OSTYPE}" in
        "linux"*) CMD_REBUILD='nixos-rebuild' ;;
        "darwin"*) CMD_REBUILD='darwin-rebuild' ;;
        *) die "Unsupported OS type: ${OSTYPE}" ;;
    esac
}

set_cmd_su() {
    ## Set the command to use for elevating priviledges.

    [ -x "$(command -v 'sudo')" ] && CMD_SU='sudo' && return 0
    [ -x "$(command -v 'doas')" ] && CMD_SU='doas' && return 0

    [ -z "${CMD_SU}" ] && die "Cannot elevate priviledges."
}

# -----------------------------------------------------------------------------

cmd_deploy_build() {
    println "Building system configuration with '${CMD_REBUILD}'"

    ${CMD_REBUILD} build --flake .#
}

cmd_deploy_switch() {
    println "Building and switching system configuration with '${CMD_REBUILD}'"

    ${CMD_REBUILD} switch --use-remote-sudo --flake .#
}

cmd_update() {
    println 'Updating flake.lock...'

    nix flake update
}

cmd_clean() {
    println 'Cleaning and optimizing the Nix Store @ /nix ...'

    ${CMD_SU} nix-collect-garbage -d
    ${CMD_SU} nix store gc --verbose
    ${CMD_SU} nix store optimise --verbose
}

cmd_repair() {
    println 'Repairing the Nix Store...'

    nix-store --verify --check-contents --repair
}

cmd_usage() {
    cat <<EOF
Usage: ${PROGRAM_NAME} [command]

Commands:
  build, b      Build system configuration
  switch, s     Build and switch system configuration

  update, u     Update flake.lock
  clean, c      Clean and optimize the Nix Store
  repair, r     Repair the Nix Store (corruption)

  help          Display this help message
EOF
}

# -----------------------------------------------------------------------------

main() {
    set_cmd_rebuild
    set_cmd_su

    [ "${#}" -eq 0 ] && cmd_usage && exit 1
    case "${@}" in
        build | b)
            shift
            cmd_deploy_build
            ;;
        switch | s)
            shift
            cmd_deploy_switch
            ;;
        update | u)
            shift
            cmd_update
            ;;
        clean | c)
            shift
            cmd_clean
            ;;
        repair | r)
            shift
            cmd_repair
            ;;
        help | --help)
            shift
            cmd_usage "${@}"
            ;;
        *) println "Unknown command: ${*}" ;;
    esac
}

main "${@}"

exit 0
