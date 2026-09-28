host := `hostname -s`

_default:
    @just --list

[macos]
build builder="":
    nh darwin build . {{ if builder == "" { "" } else if builder == "local" { "-- --builders ''" } else { "-- --builders @/etc/nix/builders/" + builder } }}

[linux]
build:
    nh os build .

[macos]
switch builder="":
    nh darwin switch . {{ if builder == "" { "" } else if builder == "local" { "-- --builders ''" } else { "-- --builders @/etc/nix/builders/" + builder } }}

[linux]
switch:
    nh os switch .

[linux]
boot:
    nh os boot .

home target="annt@wsl":
    nix build '.#homeConfigurations."{{ target }}".activationPackage'
    ./result/activate

deploy *args:
    nix develop -c clan machines update {{ args }}

check:
    scripts/ci/check-flake.sh

test:
    nix build --no-link "path:.#checks.$(nix eval --raw --impure --expr builtins.currentSystem).tests"

report ref="HEAD":
    scripts/ci/report.sh {{ ref }}

probes:
    scripts/ci/check-probes.sh

snap:
    scripts/ci/snapshot.sh

drvdiff ref="HEAD":
    scripts/ci/drvdiff.sh {{ ref }}

build-all:
    scripts/ci/build.sh

fmt:
    nix fmt

update *inputs:
    nix flake update --commit-lock-file --option commit-lockfile-summary "chore(flake): update lock file" {{ inputs }}

clean:
    nh clean all

optimise:
    sudo nix store optimise

repair:
    sudo nix-store --verify --check-contents --repair
