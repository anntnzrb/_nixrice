//! Core command execution and platform/context helpers.

use anyhow::{Result, bail};
#[cfg(test)]
use std::cell::RefCell;
use std::ffi::OsString;
#[cfg(unix)]
use std::os::unix::process::ExitStatusExt;
use std::process::Command;

use crate::tasks::{Platform, Task};

/// Boxed mock runner signature used by unit tests.
#[cfg(test)]
type MockRunFn = dyn FnMut(Vec<String>) -> Result<()>;

#[cfg(test)]
thread_local! {
    /// Thread-local command runner override used by unit tests.
    static MOCK_RUNNER: RefCell<Option<Box<MockRunFn>>> = RefCell::new(None);
}

/// Guard that clears the thread-local mock runner on scope exit.
#[cfg(test)]
struct MockRunnerGuard;

#[cfg(test)]
impl Drop for MockRunnerGuard {
    /// Reset the thread-local mock runner.
    fn drop(&mut self) {
        MOCK_RUNNER.with(|cell| {
            let _ = cell.take();
        });
    }
}

/// Success color escape sequence.
const GREEN: &str = "\x1b[1;32m";
/// Error color escape sequence.
const RED: &str = "\x1b[1;31m";
/// Info color escape sequence.
const BLUE: &str = "\x1b[1;34m";
/// Dim color escape sequence for command previews.
const DIM: &str = "\x1b[2m";
/// Reset color escape sequence.
const RESET: &str = "\x1b[0m";
/// Template token replaced by the current host.
const HOST_TOKEN: &str = "{host}";

/// Detect the current platform at compile target level.
#[cfg(target_os = "macos")]
pub(crate) const fn current_platform() -> Platform {
    Platform::Darwin
}

/// Detect the current platform at compile target level.
#[cfg(not(target_os = "macos"))]
pub(crate) const fn current_platform() -> Platform {
    Platform::Linux
}

/// Read hostname and return only the short segment before first dot.
pub(crate) fn host_shortname() -> String {
    let hostname = hostname::get().unwrap_or_else(|_| OsString::from("unknown"));
    let hostname = hostname.to_string_lossy();
    hostname.split('.').next().unwrap_or("unknown").to_string()
}

/// Print a success message line.
pub(crate) fn ok(msg: &str) {
    println!("{GREEN}✓{RESET} {msg}");
}

/// Print an error message line.
pub(crate) fn err(msg: &str) {
    eprintln!("{RED}✗{RESET} {msg}");
}

/// Print an informational message line.
pub(crate) fn info(msg: &str) {
    println!("{BLUE}→{RESET} {msg}");
}

/// Replace task context tokens in a template string.
pub(crate) fn with_context(template: &str, host: &str) -> String {
    template.replace(HOST_TOKEN, host)
}

/// Ensure a command is running on a required platform.
pub(crate) fn require_platform(required: Platform, current: Platform) -> Result<()> {
    if required == current {
        return Ok(());
    }

    let name = match required {
        Platform::Darwin => "macOS",
        Platform::Linux => "Linux",
    };
    bail!("Requires {name}");
}

/// Execute one command line invocation with optional `sudo`.
pub(crate) fn run(mut cmd: Vec<String>, sudo: bool) -> Result<()> {
    if sudo {
        cmd.insert(0, "sudo".to_string());
    }

    println!("{DIM}$ {}{RESET}", cmd.join(" "));

    #[cfg(test)]
    if let Some(result) = MOCK_RUNNER.with(|cell| {
        let mut runner = cell.borrow_mut();
        runner.as_mut().map(|mock| mock(cmd.clone()))
    }) {
        return result;
    }

    let status = Command::new(&cmd[0]).args(&cmd[1..]).status()?;
    if status.success() {
        return Ok(());
    }

    #[cfg(unix)]
    let code = status
        .code()
        .unwrap_or_else(|| -status.signal().unwrap_or(1));

    #[cfg(not(unix))]
    let code = status.code().unwrap_or(1);

    bail!("command failed: {} (exit: {code})", cmd.join(" "));
}

/// Execute a task, including platform checks, context expansion, and logging.
pub(crate) fn exec_task(task: Task, host: &str, current: Platform) -> Result<()> {
    if let Some(required) = task.platform {
        require_platform(required, current)?;
    }

    info(&with_context(task.info, host));

    let cmd = task
        .cmd
        .iter()
        .map(|arg| with_context(arg, host))
        .collect::<Vec<_>>();

    run(cmd, task.sudo)?;
    ok(task.ok);
    Ok(())
}

/// Execute a closure with a mocked command runner.
#[cfg(test)]
pub(crate) fn with_mock_run<T>(
    mock: impl FnMut(Vec<String>) -> Result<()> + 'static,
    f: impl FnOnce() -> T,
) -> T {
    MOCK_RUNNER.with(|cell| {
        let previous = cell.replace(Some(Box::new(mock)));
        assert!(
            previous.is_none(),
            "mock runner already installed for thread"
        );
    });

    let _guard = MockRunnerGuard;
    f()
}
