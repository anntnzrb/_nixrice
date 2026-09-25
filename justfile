# Liberion fleet tasks. Run `just` to list them.

host := `hostname -s`

_default:
    @just --list

# Build this machine's system without activating it
[macos]
build:
    nix build .#darwinConfigurations.{{ host }}.system

# Build this machine's system without activating it
[linux]
build:
    nixos-rebuild build --flake .#{{ host }}

# Build and activate this machine's system
[macos]
switch: build
    sudo ./result/sw/bin/darwin-rebuild switch --flake .#{{ host }}

# Build and activate this machine's system
[linux]
switch:
    nixos-rebuild switch --sudo --flake .#{{ host }}

# Build this machine's system and make it the next boot entry
[linux]
boot:
    nixos-rebuild boot --sudo --flake .#{{ host }}

# Build and activate a standalone home (hosts without a managed system)
home target="annt@wsl":
    nix build '.#homeConfigurations."{{ target }}".activationPackage'
    ./result/activate

# Build and switch remote NixOS machines through clan
deploy +machines:
    nix develop -c clan machines update {{ machines }}

# Evaluate every machine, lint, and run the flake checks (the CI gate)
check:
    scripts/ci/check-flake.sh

# Print the drvPath of every machine and standalone home
snap:
    scripts/ci/snapshot.sh

# Diff machine, home and probe drvPaths against a git ref; no output = pure refactor
drvdiff ref="HEAD":
    scripts/ci/drvdiff.sh {{ ref }}

# List the liberion toggles a machine enables (system and home users)
enabled machine=host:
    nix eval --impure --raw --expr "import ./scripts/ci/enabled.nix { flake = \"path:$PWD\"; machine = \"{{ machine }}\"; }"

# Format tracked nix files
fmt:
    nix fmt

# Update flake inputs and commit the lock file; no inputs updates all of them
update *inputs:
    nix flake update --commit-lock-file --option commit-lockfile-summary "chore(flake): update lock file" {{ inputs }}

# Delete old generations and unreferenced store paths
clean:
    nh clean all

# Deduplicate identical files in the store
optimise:
    sudo nix store optimise

# Verify store contents and repair corrupted paths
repair:
    sudo nix-store --verify --check-contents --repair
