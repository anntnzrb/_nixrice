# prints this menu
default:
    @just --list
    @printf '=> Some commands may use the NH frontend\n'

# -----------------------------------------------------------------------------
# NixOS
# -----------------------------------------------------------------------------
# build the NixOS configuration
nixos-build:
	nixos-rebuild build --flake .#

# build & activate the new NixOS configuration on next boot
nixos-boot: nixos-build
	nixos-rebuild switch --use-remote-sudo --flake .#

# build & activate the NixOS configuration now
nixos-switch: nixos-build
	nixos-rebuild boot --use-remote-sudo --flake .#

# -----------------------------------------------------------------------------
# darwin
# -----------------------------------------------------------------------------
# build the darwin configuration
darwin-build:
	darwin-rebuild build --flake .

# build & activate the darwin configuration now
darwin-switch: darwin-build
	darwin-rebuild switch --flake .

# -----------------------------------------------------------------------------
# wsl
# -----------------------------------------------------------------------------
# FIXME: find a generic way of using WSL without hard-coding a user

# build the WSL configuration
wsl-build:
	nix run home-manager -- build --flake .#"annt@wsl"

# build & activate the WSL configuration now
wsl-switch: wsl-build
	nix run home-manager -- switch --flake .#"annt@wsl"

# -----------------------------------------------------------------------------
# Nix
# -----------------------------------------------------------------------------
# perform a cleanup
nix-clean:
    nix-collect-garbage -d
    nix store gc --verbose
    nix store optimise --verbose

# attempt to repair the nix store
nix-repair: nix-clean
    nix-store --verify --check-contents --repair
    just nix-clean

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
