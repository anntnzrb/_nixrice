# Liberion fleet tasks. Run `just` to list them.

host := `hostname -s`

_default:
    @just --list

# Build this machine's system without activating it; builder: a name in
# /etc/nix/builders (a remote-builders builder), "local" for none, empty for the defaults
[macos]
build builder="":
    nix build .#darwinConfigurations.{{ host }}.system {{ if builder == "" { "" } else if builder == "local" { "--builders ''" } else { "--builders @/etc/nix/builders/" + builder } }}

# Build this machine's system without activating it
[linux]
build:
    nixos-rebuild build --flake .#{{ host }}

# Build and activate this machine's system (builder: as for build)
[macos]
switch builder="": (build builder)
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

# Run the eval-time tests (tests/): lib discovery and fleet SSH access
test:
    nix build --no-link "path:.#checks.$(nix eval --raw --impure --expr builtins.currentSystem).tests"

# What the working tree changes on each machine and home versus a git ref
report ref="HEAD":
    scripts/ci/report.sh {{ ref }}

# Import every feature into its probe host; fail on unexpected eval errors
probes:
    scripts/ci/check-probes.sh

# Print the drvPath of every machine and standalone home
snap:
    scripts/ci/snapshot.sh

# Diff machine, home and probe drvPaths against a git ref; no output = pure refactor
drvdiff ref="HEAD":
    scripts/ci/drvdiff.sh {{ ref }}

# Build every machine and home this platform can build
build-all:
    scripts/ci/build.sh

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
