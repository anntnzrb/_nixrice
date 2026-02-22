//! CLI entrypoint and command orchestration for the `rice` tool.

pub(crate) mod actions;
pub(crate) mod cli;
pub(crate) mod tasks;

#[cfg(test)]
pub(crate) mod unit_tests;

use anyhow::Result;
#[cfg(not(test))]
use clap::Parser;

use crate::cli::{
    Cli, Commands, DarwinCommands, FlakeCommands, HomeCommands, NixCommands, NixosCommands,
    SystemCommands,
};
use crate::tasks::{
    DARWIN_BUILD, DARWIN_SWITCH, FLAKE_CHECK, FLAKE_FMT, NIX_OPTIMISE, NIX_REPAIR, NIXOS_BOOT,
    NIXOS_BUILD, NIXOS_SWITCH, Platform,
};

/// Parse process arguments and execute command flow.
#[cfg(not(test))]
pub fn run_main() {
    let cli = Cli::parse();
    if let Err(error) = run_cli(cli) {
        actions::err(&error.to_string());
        std::process::exit(1);
    }
}

/// Route parsed CLI commands using detected runtime context.
fn run_cli(cli: Cli) -> Result<()> {
    let host = actions::host_shortname();
    let current = actions::current_platform();
    run_cli_with_context(cli, &host, current)
}

/// Route parsed CLI commands with explicit runtime context.
fn run_cli_with_context(cli: Cli, host: &str, current: Platform) -> Result<()> {
    match cli.command {
        Commands::System { command } => match command {
            SystemCommands::Build => {
                actions::exec_task(
                    if current == Platform::Darwin {
                        DARWIN_BUILD
                    } else {
                        NIXOS_BUILD
                    },
                    host,
                    current,
                )?;
            }
            SystemCommands::Switch => {
                if current == Platform::Darwin {
                    actions::exec_task(DARWIN_BUILD, host, current)?;
                    actions::exec_task(DARWIN_SWITCH, host, current)?;
                } else {
                    actions::exec_task(NIXOS_BUILD, host, current)?;
                    actions::exec_task(NIXOS_SWITCH, host, current)?;
                }
            }
        },
        Commands::Home { command } => match command {
            HomeCommands::Build { user, host } => actions::home_build(&user, &host)?,
            HomeCommands::Switch { user, host } => actions::home_switch(&user, &host)?,
        },
        Commands::Nixos { command } => match command {
            NixosCommands::Build => actions::exec_task(NIXOS_BUILD, host, current)?,
            NixosCommands::Boot => actions::exec_task(NIXOS_BOOT, host, current)?,
            NixosCommands::Switch => actions::exec_task(NIXOS_SWITCH, host, current)?,
        },
        Commands::Darwin { command } => match command {
            DarwinCommands::Build => actions::exec_task(DARWIN_BUILD, host, current)?,
            DarwinCommands::Switch => actions::exec_task(DARWIN_SWITCH, host, current)?,
        },
        Commands::Nix { command } => match command {
            NixCommands::Optimise => actions::exec_task(NIX_OPTIMISE, host, current)?,
            NixCommands::Repair => actions::exec_task(NIX_REPAIR, host, current)?,
            NixCommands::Clean => actions::nix_clean()?,
        },
        Commands::Flake { command } => match command {
            FlakeCommands::Check => actions::exec_task(FLAKE_CHECK, host, current)?,
            FlakeCommands::Fmt => actions::exec_task(FLAKE_FMT, host, current)?,
            FlakeCommands::Update { name } => actions::flake_update(&name)?,
        },
    }

    Ok(())
}
