//! Command execution helpers and side-effecting workflows.

pub(crate) mod core;
pub(crate) mod flake;
pub(crate) mod home;
pub(crate) mod nix;

use anyhow::Result;
#[cfg(test)]
use std::path::PathBuf;

use crate::tasks::{Platform, Task};

/// Detect the current compile-target platform.
pub(crate) const fn current_platform() -> Platform {
    core::current_platform()
}

/// Read hostname and return the short segment.
pub(crate) fn host_shortname() -> String {
    core::host_shortname()
}

/// Execute one immutable task definition.
pub(crate) fn exec_task(task: Task, host: &str, current: Platform) -> Result<()> {
    core::exec_task(task, host, current)
}

/// Emit an error line to stderr.
pub(crate) fn err(msg: &str) {
    core::err(msg);
}

/// Build the requested home-manager profile.
pub(crate) fn home_build(user: &str, host: &str) -> Result<()> {
    home::home_build(user, host)
}

/// Build and switch the requested home-manager profile.
pub(crate) fn home_switch(user: &str, host: &str) -> Result<()> {
    home::home_switch(user, host)
}

/// Execute nix maintenance cleanup routines.
pub(crate) fn nix_clean() -> Result<()> {
    nix::nix_clean()
}

/// Update one or all flake inputs.
pub(crate) fn flake_update(name: &str) -> Result<()> {
    flake::flake_update(name)
}

/// Replace task context tokens in command templates.
#[cfg(test)]
pub(crate) fn with_context(template: &str, host: &str) -> String {
    core::with_context(template, host)
}

/// Validate the current platform against a requirement.
#[cfg(test)]
pub(crate) fn require_platform(required: Platform, current: Platform) -> Result<()> {
    core::require_platform(required, current)
}

/// Execute one command line with optional `sudo`.
#[cfg(test)]
pub(crate) fn run(cmd: Vec<String>, sudo: bool) -> Result<()> {
    core::run(cmd, sudo)
}

/// Install a thread-local mock command runner for the duration of a closure.
#[cfg(test)]
pub(crate) fn with_mock_run<T>(
    mock: impl FnMut(Vec<String>) -> Result<()> + 'static,
    f: impl FnOnce() -> T,
) -> T {
    core::with_mock_run(mock, f)
}

/// Execute nix cleanup routines with an explicit home path.
#[cfg(test)]
pub(crate) fn nix_clean_with_home(home: Option<PathBuf>) -> Result<()> {
    nix::nix_clean_with_home(home)
}
