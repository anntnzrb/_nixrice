# get the current system host name
hostname := `hostname | cut -d "." -f 1`

# prints this menu
default:
    @just --list

# -----------------------------------------------------------------------------
# NixOS
# -----------------------------------------------------------------------------

# build the NixOS configuration
[linux]
build:
    nixos-rebuild build --flake .#

# build & activate the new NixOS configuration on next boot
[linux]
boot: build
    nixos-rebuild boot --use-remote-sudo --flake .#

# build & activate the NixOS configuration now
[linux]
switch: build
    nixos-rebuild switch --use-remote-sudo --flake .#

# -----------------------------------------------------------------------------
# darwin
# -----------------------------------------------------------------------------

# build the darwin configuration
[macos]
build:
    nix build ".#darwinConfigurations.{{hostname}}.system"

# build & activate the darwin configuration now
[macos]
switch: build
	./result/sw/bin/darwin-rebuild switch --flake ".#{{hostname}}"

# -----------------------------------------------------------------------------
# home-manager
# -----------------------------------------------------------------------------

# build the home-manager configuration
hm-build user host:
	nix build ".#homeConfigurations.{{user}}@{{host}}.activationPackage"

# build & activate the home-manager configuration now
hm-switch user host: (hm-build user host)
    ./result/activate

# -----------------------------------------------------------------------------
# Nix
# -----------------------------------------------------------------------------

# perform a cleanup
nix-clean:
    sudo nix-collect-garbage --max-jobs auto --cores 0 --delete-old

# optimise the nix store
nix-optimise: nix-clean
    rm -Rf ${HOME}/.cache/ >/dev/null
    sudo nix store optimise

# attempt to repair the nix store
nix-repair: nix-optimise
    sudo nix-store --verify --check-contents --repair

# -----------------------------------------------------------------------------
# nixos-generators
# -----------------------------------------------------------------------------

# build nomad (Linux x86_64) ISO
iso-nomad-x86_64-linux:
    nix build .#isoConfigurations.nomad

# -----------------------------------------------------------------------------
# flake
# -----------------------------------------------------------------------------

# update all flake inputs
nix-flake-update-all:
    nix flake update --commit-lock-file --option commit-lockfile-summary 'chore(flake): update lockfile'

# update a single flake input
nix-flake-update *ARGS:
    nix flake update {{ ARGS }}
    git add flake.lock && git commit -m 'chore(flake): update input ({{ARGS}})'

# fmt src tree
fmt:
    nix fmt
