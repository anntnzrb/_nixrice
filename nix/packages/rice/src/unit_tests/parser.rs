//! Parser and lightweight helper tests.

use crate::actions;
use crate::cli::{Commands, FlakeCommands, HomeCommands};
use crate::tasks::{DARWIN_BUILD, Platform};
use crate::unit_tests::support::parse_cli;

/// Validate default positional values for home build.
#[test]
fn parse_home_build_defaults() {
    let cli = parse_cli(&["rice", "home", "build"]);
    match cli.command {
        Commands::Home { command } => match command {
            HomeCommands::Build { user, host } => {
                assert_eq!(user, "annt");
                assert_eq!(host, "wsl");
            }
            HomeCommands::Switch { .. } => panic!("expected home build"),
        },
        Commands::System { .. }
        | Commands::Nixos { .. }
        | Commands::Darwin { .. }
        | Commands::Nix { .. }
        | Commands::Flake { .. } => panic!("expected home command"),
    }
}

/// Validate custom positional values for home switch.
#[test]
fn parse_home_switch_overrides_defaults() {
    let cli = parse_cli(&["rice", "home", "switch", "alice", "mbp"]);
    match cli.command {
        Commands::Home { command } => match command {
            HomeCommands::Switch { user, host } => {
                assert_eq!(user, "alice");
                assert_eq!(host, "mbp");
            }
            HomeCommands::Build { .. } => panic!("expected home switch"),
        },
        Commands::System { .. }
        | Commands::Nixos { .. }
        | Commands::Darwin { .. }
        | Commands::Nix { .. }
        | Commands::Flake { .. } => panic!("expected home command"),
    }
}

/// Validate `flake update all` argument parsing.
#[test]
fn parse_flake_update_all() {
    let cli = parse_cli(&["rice", "flake", "update", "all"]);
    match cli.command {
        Commands::Flake { command } => match command {
            FlakeCommands::Update { name } => assert_eq!(name, "all"),
            FlakeCommands::Check | FlakeCommands::Fmt => panic!("expected flake update"),
        },
        Commands::System { .. }
        | Commands::Home { .. }
        | Commands::Nixos { .. }
        | Commands::Darwin { .. }
        | Commands::Nix { .. } => panic!("expected flake command"),
    }
}

/// Validate host token substitution in task command templates.
#[test]
fn task_context_substitution_works() {
    let cmd = DARWIN_BUILD
        .cmd
        .iter()
        .map(|arg| actions::with_context(arg, "beirut"))
        .collect::<Vec<_>>();
    assert_eq!(cmd[2], ".#darwinConfigurations.beirut.system");
}

/// Validate the detected platform matches compile-time target configuration.
#[test]
fn current_platform_matches_target_cfg() {
    let expected = if cfg!(target_os = "macos") {
        Platform::Darwin
    } else {
        Platform::Linux
    };
    assert_eq!(actions::current_platform(), expected);
}

/// Validate hostname helper returns short segment without dots.
#[test]
fn host_shortname_has_no_domain_suffix() {
    let host = actions::host_shortname();
    assert!(!host.is_empty());
    assert!(!host.contains('.'));
}
