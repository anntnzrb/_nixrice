//! Nix maintenance task definitions.

use crate::tasks::Task;

/// Task that optimizes the local Nix store.
pub(crate) const NIX_OPTIMISE: Task = Task {
    info: "Optimizing nix store...",
    cmd: &["nix", "store", "optimise"],
    ok: "Nix store optimized",
    sudo: true,
    platform: None,
};

/// Task that verifies and repairs the local Nix store.
pub(crate) const NIX_REPAIR: Task = Task {
    info: "Repairing nix store...",
    cmd: &["nix-store", "--verify", "--check-contents", "--repair"],
    ok: "Nix store repaired",
    sudo: true,
    platform: None,
};
