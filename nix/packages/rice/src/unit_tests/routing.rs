//! Command routing tests for high-level CLI flows.

use crate::tasks::Platform;
use crate::unit_tests::support::{
    capture_commands, capture_commands_with_failure, cmd, parse_cli, run_cli_capture,
};

/// Validate Linux system build routes to NixOS build command.
#[test]
fn system_build_linux_routes_to_nixos_build() {
    let (result, commands) =
        run_cli_capture(&["rice", "system", "build"], "zadar", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&["nixos-rebuild", "build", "--flake", ".#"])]
    );
}

/// Validate Darwin system build uses host-specific build target.
#[test]
fn system_build_darwin_routes_to_darwin_build() {
    let (result, commands) =
        run_cli_capture(&["rice", "system", "build"], "beirut", Platform::Darwin);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&[
            "nix",
            "build",
            ".#darwinConfigurations.beirut.system"
        ])]
    );
}

/// Validate Linux system switch runs build then switch.
#[test]
fn system_switch_linux_runs_two_steps() {
    let (result, commands) =
        run_cli_capture(&["rice", "system", "switch"], "zadar", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![
            cmd(&["nixos-rebuild", "build", "--flake", ".#"]),
            cmd(&["nixos-rebuild", "switch", "--sudo", "--flake", ".#"])
        ]
    );
}

/// Validate Darwin system switch runs build then sudo switch.
#[test]
fn system_switch_darwin_runs_two_steps() {
    let (result, commands) =
        run_cli_capture(&["rice", "system", "switch"], "beirut", Platform::Darwin);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![
            cmd(&["nix", "build", ".#darwinConfigurations.beirut.system"]),
            cmd(&[
                "sudo",
                "./result/sw/bin/darwin-rebuild",
                "switch",
                "--flake",
                ".#beirut"
            ])
        ]
    );
}

/// Validate Darwin commands fail when current platform is Linux.
#[test]
fn darwin_build_rejects_linux_platform() {
    let (result, commands) =
        run_cli_capture(&["rice", "darwin", "build"], "zadar", Platform::Linux);
    let error = result.expect_err("platform mismatch should fail");
    assert_eq!(error.to_string(), "Requires macOS");
    assert!(commands.is_empty());
}

/// Validate NixOS build command route.
#[test]
fn nixos_build_routes_to_build_command() {
    let (result, commands) = run_cli_capture(&["rice", "nixos", "build"], "zadar", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&["nixos-rebuild", "build", "--flake", ".#"])]
    );
}

/// Validate NixOS boot command route.
#[test]
fn nixos_boot_routes_to_boot_command() {
    let (result, commands) = run_cli_capture(&["rice", "nixos", "boot"], "zadar", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&["nixos-rebuild", "boot", "--sudo", "--flake", ".#"])]
    );
}

/// Validate NixOS switch command route.
#[test]
fn nixos_switch_routes_to_switch_command() {
    let (result, commands) =
        run_cli_capture(&["rice", "nixos", "switch"], "zadar", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&["nixos-rebuild", "switch", "--sudo", "--flake", ".#"])]
    );
}

/// Validate Darwin switch command route.
#[test]
fn darwin_switch_routes_to_switch_command() {
    let (result, commands) =
        run_cli_capture(&["rice", "darwin", "switch"], "beirut", Platform::Darwin);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&[
            "sudo",
            "./result/sw/bin/darwin-rebuild",
            "switch",
            "--flake",
            ".#beirut"
        ])]
    );
}

/// Validate home build route executes only build command.
#[test]
fn home_build_runs_single_step() {
    let (result, commands) = run_cli_capture(
        &["rice", "home", "build", "alice", "mbp"],
        "ignored",
        Platform::Linux,
    );
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&[
            "nix",
            "build",
            ".#homeConfigurations.alice@mbp.activationPackage"
        ])]
    );
}

/// Validate home switch runs build then activate sequence.
#[test]
fn home_switch_runs_build_then_activate() {
    let (result, commands) = run_cli_capture(
        &["rice", "home", "switch", "alice", "mbp"],
        "ignored",
        Platform::Linux,
    );
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![
            cmd(&[
                "nix",
                "build",
                ".#homeConfigurations.alice@mbp.activationPackage"
            ]),
            cmd(&["./result/activate"])
        ]
    );
}

/// Validate nix optimise route includes sudo command prefix.
#[test]
fn nix_optimise_uses_sudo() {
    let (result, commands) =
        run_cli_capture(&["rice", "nix", "optimise"], "ignored", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(commands, vec![cmd(&["sudo", "nix", "store", "optimise"])]);
}

/// Validate nix repair route includes sudo command prefix.
#[test]
fn nix_repair_uses_sudo() {
    let (result, commands) =
        run_cli_capture(&["rice", "nix", "repair"], "ignored", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&[
            "sudo",
            "nix-store",
            "--verify",
            "--check-contents",
            "--repair"
        ])]
    );
}

/// Validate nix clean route runs both cleanup commands.
#[test]
fn nix_clean_route_runs_cleanup_commands() {
    let (result, commands) = run_cli_capture(&["rice", "nix", "clean"], "ignored", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&["nh", "clean", "all"]), cmd(&["nh", "clean", "user"])]
    );
}

/// Validate flake fmt route runs pre-commit over all files.
#[test]
fn flake_fmt_runs_pre_commit() {
    let (result, commands) = run_cli_capture(&["rice", "flake", "fmt"], "ignored", Platform::Linux);
    assert!(result.is_ok());
    assert_eq!(commands, vec![cmd(&["pre-commit", "run", "--all-files"])]);
}

/// Validate flake update-all route uses lockfile commit flags.
#[test]
fn flake_update_all_runs_commit_lockfile_flow() {
    let (result, commands) = run_cli_capture(
        &["rice", "flake", "update", "all"],
        "ignored",
        Platform::Linux,
    );
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![cmd(&[
            "nix",
            "flake",
            "update",
            "--commit-lock-file",
            "--option",
            "commit-lockfile-summary",
            "chore(flake): update lockfile"
        ])]
    );
}

/// Validate flake single-input update commits only that input change.
#[test]
fn flake_update_single_input_runs_git_flow() {
    let (result, commands) = run_cli_capture(
        &["rice", "flake", "update", "fenix"],
        "ignored",
        Platform::Linux,
    );
    assert!(result.is_ok());
    assert_eq!(
        commands,
        vec![
            cmd(&["nix", "flake", "update", "fenix"]),
            cmd(&["git", "add", "flake.lock"]),
            cmd(&["git", "commit", "-m", "chore(flake): update input (fenix)"])
        ]
    );
}

/// Validate wrapper `run_cli` uses detected runtime context.
#[test]
fn run_cli_wrapper_executes_commands() {
    let cli = parse_cli(&["rice", "flake", "check"]);
    let (result, commands) = capture_commands(|| crate::run_cli(cli));
    assert!(result.is_ok());
    assert_eq!(commands, vec![cmd(&["nix", "flake", "check", "."])]);
}

/// Validate system build route propagates command failures.
#[test]
fn run_cli_system_build_propagates_exec_error() {
    let cli = parse_cli(&["rice", "system", "build"]);
    let (result, commands) = capture_commands_with_failure(
        || crate::run_cli_with_context(cli, "zadar", Platform::Linux),
        1,
    );
    assert!(result.is_err());
    assert_eq!(
        commands,
        vec![cmd(&["nixos-rebuild", "build", "--flake", ".#"])]
    );
}
