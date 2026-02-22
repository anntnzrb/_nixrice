//! Darwin task definitions.

use crate::tasks::{Platform, Task};

/// Darwin task that builds host configuration output.
pub(crate) const DARWIN_BUILD: Task = Task {
    info: "Building Darwin for {host}...",
    cmd: &["nix", "build", ".#darwinConfigurations.{host}.system"],
    ok: "Darwin build complete",
    sudo: false,
    platform: Some(Platform::Darwin),
};

/// Darwin task that switches active configuration.
pub(crate) const DARWIN_SWITCH: Task = Task {
    info: "Switching...",
    cmd: &[
        "./result/sw/bin/darwin-rebuild",
        "switch",
        "--flake",
        ".#{host}",
    ],
    ok: "Darwin switch complete",
    sudo: true,
    platform: Some(Platform::Darwin),
};
