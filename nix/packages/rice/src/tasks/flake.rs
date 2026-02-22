//! Flake-related task definitions.

use crate::tasks::Task;

/// Task that checks flake evaluation and checks.
pub(crate) const FLAKE_CHECK: Task = Task {
    info: "Checking flake...",
    cmd: &["nix", "flake", "check", "."],
    ok: "Flake check passed",
    sudo: false,
    platform: None,
};

/// Task that runs repository formatting hooks.
pub(crate) const FLAKE_FMT: Task = Task {
    info: "Formatting...",
    cmd: &["pre-commit", "run", "--all-files"],
    ok: "Format complete",
    sudo: false,
    platform: None,
};
