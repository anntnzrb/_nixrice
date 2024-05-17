# prints this menu
default:
    @just --list
    @printf '=> Some commands may use the NH frontend\n'

# -----------------------------------------------------------------------------
# NixOS
# -----------------------------------------------------------------------------

# build the NixOS configuration
build:
    nh os build .

# build & activate the new NixOS configuration on next boot
boot: build
    nh os boot .

# build & activate the NixOS configuration now
switch: build
    nh os switch .

# -----------------------------------------------------------------------------
# Nix
# -----------------------------------------------------------------------------

# perform a cleanup
clean:
    nh clean all

# perform a full cleanup
clean-full-wipe: clean
    nix-collect-garbage -d
    nix store gc --verbose
    nix store optimise --verbose

# attempt to repair the nix store
repair: clean-full-wipe
    nix-store --verify --check-contents --repair
    just clean-full-wipe

# -----------------------------------------------------------------------------
# flake
# -----------------------------------------------------------------------------

# update all flake inputs
flake-update-all:
    nix flake update --commit-lock-file --commit-lockfile-summary 'chore(flake): update lockfile'

# update a single flake input
flake-update *ARGS:
    nix flake lock --update-input {{ARGS}}
    git add flake.nix
    git commit -m 'chore(flake): update lockfile ({{ARGS}})'
