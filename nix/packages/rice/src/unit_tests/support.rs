//! Shared test helpers for command capture and mock execution.

use anyhow::{Result, anyhow};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::actions;
use crate::cli::Cli;
use crate::tasks::Platform;

/// Parse CLI arguments and return the typed command tree.
pub(crate) fn parse_cli(args: &[&str]) -> Cli {
    clap::Parser::try_parse_from(args).expect("parse should succeed")
}

/// Build a command vector from string slices.
pub(crate) fn cmd(parts: &[&str]) -> Vec<String> {
    parts.iter().map(|part| (*part).to_string()).collect()
}

/// Run an action while capturing all spawned command lines.
pub(crate) fn capture_commands(
    action: impl FnOnce() -> Result<()>,
) -> (Result<()>, Vec<Vec<String>>) {
    let commands = Rc::new(RefCell::new(Vec::new()));
    let commands_for_mock = Rc::clone(&commands);

    let result = actions::with_mock_run(
        move |line| {
            commands_for_mock.borrow_mut().push(line);
            Ok(())
        },
        action,
    );

    let commands = Rc::try_unwrap(commands).expect("single owner").into_inner();
    (result, commands)
}

/// Run an action while failing on the selected command index.
pub(crate) fn capture_commands_with_failure(
    action: impl FnOnce() -> Result<()>,
    fail_at: usize,
) -> (Result<()>, Vec<Vec<String>>) {
    let commands = Rc::new(RefCell::new(Vec::new()));
    let calls = Rc::new(RefCell::new(0usize));
    let commands_for_mock = Rc::clone(&commands);
    let calls_for_mock = Rc::clone(&calls);

    let result = actions::with_mock_run(
        move |line| {
            commands_for_mock.borrow_mut().push(line);
            let mut calls = calls_for_mock.borrow_mut();
            *calls += 1;
            if *calls == fail_at {
                return Err(anyhow!("mock failure at call {fail_at}"));
            }
            Ok(())
        },
        action,
    );

    let commands = Rc::try_unwrap(commands).expect("single owner").into_inner();
    (result, commands)
}

/// Parse and execute CLI with explicit host and platform while capturing commands.
pub(crate) fn run_cli_capture(
    args: &[&str],
    host: &str,
    current: Platform,
) -> (Result<()>, Vec<Vec<String>>) {
    let cli = parse_cli(args);
    capture_commands(|| crate::run_cli_with_context(cli, host, current))
}

/// Build a unique temporary directory path.
pub(crate) fn temp_path(prefix: &str) -> PathBuf {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system time should be after unix epoch")
        .as_nanos();
    std::env::temp_dir().join(format!("{prefix}-{}-{nanos}", std::process::id()))
}
