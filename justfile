# prints this menu
default:
    @just --list
    @printf '=> Some commands may use the NH frontend\n'

# -----------------------------------------------------------------------------
# NixOS
# -----------------------------------------------------------------------------

# build the NixOS configuration
nixos-build:
    nh os build .

# build & activate the new NixOS configuration on next boot
nixos-boot: nixos-build
    nh os boot .

# build & activate the NixOS configuration now
nixos-switch: nixos-build
    nh os switch .

# -----------------------------------------------------------------------------
# darwin
# -----------------------------------------------------------------------------

# build the darwin configuration
darwin-build:
	nix run nix-darwin -- build --flake .

# build & activate the new darwin configuration on next boot
darwin-boot: darwin-build
	nix run nix-darwin -- boot --flake .

# build & activate the darwin configuration now
darwin-switch: darwin-build
	nix run nix-darwin -- switch --flake .

# -----------------------------------------------------------------------------
# Nix
# -----------------------------------------------------------------------------

# perform a cleanup
nix-clean:
    nh clean all

# perform a full cleanup
nix-clean-full-wipe: nix-clean
    nix-collect-garbage -d
    nix store gc --verbose
    nix store optimise --verbose

# attempt to repair the nix store
nix-repair: nix-clean-full-wipe
    nix-store --verify --check-contents --repair
    just nix-clean-full-wipe

# -----------------------------------------------------------------------------
# flake
# -----------------------------------------------------------------------------

# update all flake inputs
nix-flake-update-all:
    nix flake update --commit-lock-file --commit-lockfile-summary 'chore(flake): update lockfile'

# update a single flake input
nix-flake-update *ARGS:
    nix flake lock --update-input {{ARGS}}
    git add flake.lock && git commit -m 'chore(flake): update lockfile ({{ARGS}})'

# fmt
fmt:
	nix fmt
