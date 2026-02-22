//! Linux/NixOS task definitions.

use crate::tasks::{Platform, Task};

/// Linux task that builds system configuration.
pub(crate) const NIXOS_BUILD: Task = Task {
    info: "Building NixOS...",
    cmd: &["nixos-rebuild", "build", "--flake", ".#"],
    ok: "NixOS build complete",
    sudo: false,
    platform: Some(Platform::Linux),
};

/// Linux task that stages next boot configuration.
pub(crate) const NIXOS_BOOT: Task = Task {
    info: "Setting boot...",
    cmd: &["nixos-rebuild", "boot", "--sudo", "--flake", ".#"],
    ok: "Boot set",
    sudo: false,
    platform: Some(Platform::Linux),
};

/// Linux task that switches active system configuration.
pub(crate) const NIXOS_SWITCH: Task = Task {
    info: "Switching...",
    cmd: &["nixos-rebuild", "switch", "--sudo", "--flake", ".#"],
    ok: "NixOS switch complete",
    sudo: false,
    platform: Some(Platform::Linux),
};
