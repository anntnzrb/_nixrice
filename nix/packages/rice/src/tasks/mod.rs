//! Immutable task metadata used by command routing.

pub(crate) mod darwin;
pub(crate) mod flake;
pub(crate) mod nix;
pub(crate) mod nixos;

/// Darwin build task.
pub(crate) const DARWIN_BUILD: Task = darwin::DARWIN_BUILD;
/// Darwin switch task.
pub(crate) const DARWIN_SWITCH: Task = darwin::DARWIN_SWITCH;
/// Flake check task.
pub(crate) const FLAKE_CHECK: Task = flake::FLAKE_CHECK;
/// Flake formatting task.
pub(crate) const FLAKE_FMT: Task = flake::FLAKE_FMT;
/// Nix optimize task.
pub(crate) const NIX_OPTIMISE: Task = nix::NIX_OPTIMISE;
/// Nix repair task.
pub(crate) const NIX_REPAIR: Task = nix::NIX_REPAIR;
/// NixOS boot task.
pub(crate) const NIXOS_BOOT: Task = nixos::NIXOS_BOOT;
/// NixOS build task.
pub(crate) const NIXOS_BUILD: Task = nixos::NIXOS_BUILD;
/// NixOS switch task.
pub(crate) const NIXOS_SWITCH: Task = nixos::NIXOS_SWITCH;

/// Supported runtime platforms.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum Platform {
    /// Apple Darwin systems.
    Darwin,
    /// Linux systems.
    Linux,
}

/// Immutable description of one executable task.
#[derive(Clone, Copy, Debug)]
pub(crate) struct Task {
    /// Message shown before command execution.
    pub(crate) info: &'static str,
    /// Process command and arguments.
    pub(crate) cmd: &'static [&'static str],
    /// Success message shown after execution.
    pub(crate) ok: &'static str,
    /// Whether command should run through `sudo`.
    pub(crate) sudo: bool,
    /// Optional platform restriction for this task.
    pub(crate) platform: Option<Platform>,
}
