use super::*;

#[test]
fn parse_home_build_defaults() {
    let cli = Cli::try_parse_from(["rice", "home", "build"]).expect("parse should succeed");
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

#[test]
fn parse_home_switch_overrides_defaults() {
    let cli = Cli::try_parse_from(["rice", "home", "switch", "alice", "mbp"])
        .expect("parse should succeed");
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

#[test]
fn task_context_substitution_works() {
    let cmd = DARWIN_BUILD
        .cmd
        .iter()
        .map(|arg| with_context(arg, "beirut"))
        .collect::<Vec<_>>();
    assert_eq!(cmd[2], ".#darwinConfigurations.beirut.system");
}

#[test]
fn platform_requirement_errors_on_mismatch() {
    let result = require_platform(Platform::Linux, Platform::Darwin);
    assert_eq!(result.unwrap_err().to_string(), "Requires Linux");
}

#[test]
fn parse_flake_update_all() {
    let cli =
        Cli::try_parse_from(["rice", "flake", "update", "all"]).expect("parse should succeed");
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
