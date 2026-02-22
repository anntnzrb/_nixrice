//! Action-level tests for helpers and workflows.

use crate::actions;
use crate::tasks::Platform;
use crate::unit_tests::support::{capture_commands, capture_commands_with_failure, cmd, temp_path};

/// Validate platform requirement success for matching platform.
#[test]
fn platform_requirement_allows_match() {
    let result = actions::require_platform(Platform::Linux, Platform::Linux);
    assert!(result.is_ok());
}

/// Validate platform requirement error for mismatched platform.
#[test]
fn platform_requirement_errors_on_mismatch() {
    let result = actions::require_platform(Platform::Linux, Platform::Darwin);
    assert_eq!(result.expect_err("must fail").to_string(), "Requires Linux");
}

/// Validate command runner prepends sudo before execution.
#[test]
fn run_prepends_sudo_when_requested() {
    let (result, commands) = capture_commands(|| actions::run(cmd(&["echo", "ok"]), true));
    assert!(result.is_ok());
    assert_eq!(commands, vec![cmd(&["sudo", "echo", "ok"])]);
}

/// Validate command runner returns error when process exits non-zero.
#[cfg(unix)]
#[test]
fn run_reports_non_zero_exit() {
    let result = actions::run(cmd(&["sh", "-c", "exit 7"]), false);
    let error = result.expect_err("command should fail");
    assert!(error.to_string().contains("exit: 7"));
}

/// Validate command runner returns success when process exits zero.
#[cfg(unix)]
#[test]
fn run_reports_zero_exit() {
    let result = actions::run(cmd(&["sh", "-c", "exit 0"]), false);
    assert!(result.is_ok());
}

/// Validate error logger function is callable from test paths.
#[test]
fn err_logger_is_callable() {
    actions::err("synthetic error");
}

/// Validate nix clean removes cache dir and runs both cleanup commands.
#[test]
fn nix_clean_removes_cache_and_runs_cleanup() {
    let home = temp_path("rice-home");
    let cache_dir = home.join(".cache/nix");
    std::fs::create_dir_all(&cache_dir).expect("cache dir should be created");

    let (result, commands) = capture_commands(|| actions::nix_clean_with_home(Some(home.clone())));
    assert!(result.is_ok());
    assert!(!cache_dir.exists());
    assert_eq!(
        commands,
        vec![cmd(&["nh", "clean", "all"]), cmd(&["nh", "clean", "user"])]
    );

    let _ = std::fs::remove_dir_all(home);
}

/// Validate home build propagates command execution failures.
#[test]
fn home_build_propagates_run_error() {
    let (result, commands) =
        capture_commands_with_failure(|| actions::home_build("alice", "mbp"), 1);
    assert!(result.is_err());
    assert_eq!(commands.len(), 1);
}

/// Validate nix clean propagates first cleanup command failure.
#[test]
fn nix_clean_propagates_first_cleanup_error() {
    let (result, commands) =
        capture_commands_with_failure(|| actions::nix_clean_with_home(None), 1);
    assert!(result.is_err());
    assert_eq!(commands, vec![cmd(&["nh", "clean", "all"])]);
}

/// Validate nix clean propagates second cleanup command failure.
#[test]
fn nix_clean_propagates_second_cleanup_error() {
    let (result, commands) =
        capture_commands_with_failure(|| actions::nix_clean_with_home(None), 2);
    assert!(result.is_err());
    assert_eq!(
        commands,
        vec![cmd(&["nh", "clean", "all"]), cmd(&["nh", "clean", "user"])]
    );
}

/// Validate update-all flow propagates command execution failures.
#[test]
fn flake_update_all_propagates_run_error() {
    let (result, commands) = capture_commands_with_failure(|| actions::flake_update("all"), 1);
    assert!(result.is_err());
    assert_eq!(commands.len(), 1);
}

/// Validate single-input update propagates update command failure.
#[test]
fn flake_update_single_propagates_update_error() {
    let (result, commands) = capture_commands_with_failure(|| actions::flake_update("fenix"), 1);
    assert!(result.is_err());
    assert_eq!(commands, vec![cmd(&["nix", "flake", "update", "fenix"])]);
}

/// Validate single-input update propagates git-add command failure.
#[test]
fn flake_update_single_propagates_git_add_error() {
    let (result, commands) = capture_commands_with_failure(|| actions::flake_update("fenix"), 2);
    assert!(result.is_err());
    assert_eq!(
        commands,
        vec![
            cmd(&["nix", "flake", "update", "fenix"]),
            cmd(&["git", "add", "flake.lock"])
        ]
    );
}

/// Validate single-input update propagates git-commit command failure.
#[test]
fn flake_update_single_propagates_git_commit_error() {
    let (result, commands) = capture_commands_with_failure(|| actions::flake_update("fenix"), 3);
    assert!(result.is_err());
    assert_eq!(
        commands,
        vec![
            cmd(&["nix", "flake", "update", "fenix"]),
            cmd(&["git", "add", "flake.lock"]),
            cmd(&["git", "commit", "-m", "chore(flake): update input (fenix)"])
        ]
    );
}
