#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4", features = ["derive"] }
//! anyhow = "1"
//! gethostname = "0.5"
//! ```

use anyhow::Result;
use clap::{CommandFactory, Parser};

macro_rules! include_mod {
    ($($name:ident),*) => {
        $(mod $name { include!(concat!(env!("RUST_SCRIPT_BASE_PATH"), "/rice/", stringify!($name), ".rs")); })*
    };
}

include_mod!(cli, platform, output, exec, commands);

use cli::*;
use platform::Platform;

fn dispatch(cmd: Commands) -> Result<()> {
    match cmd {
        Commands::System { command } => match command {
            SystemCommands::Build => match Platform::detect() {
                Platform::Linux => commands::nixos::build(),
                Platform::Darwin => commands::darwin::build(),
            },
            SystemCommands::Switch => match Platform::detect() {
                Platform::Linux => commands::nixos::switch(),
                Platform::Darwin => commands::darwin::switch(),
            },
        },
        Commands::Home { command } => match command {
            HomeCommands::Build { user, host } => commands::home::build(&user, &host),
            HomeCommands::Switch { user, host } => commands::home::switch(&user, &host),
        },
        Commands::Nixos { command } => match command {
            NixosCommands::Build => commands::nixos::build(),
            NixosCommands::Boot => commands::nixos::boot(),
            NixosCommands::Switch => commands::nixos::switch(),
        },
        Commands::Darwin { command } => match command {
            DarwinCommands::Build => commands::darwin::build(),
            DarwinCommands::Switch => commands::darwin::switch(),
        },
        Commands::Nix { command } => match command {
            NixCommands::Clean => commands::nix::clean(),
            NixCommands::Optimise => commands::nix::optimise(),
            NixCommands::Repair => commands::nix::repair(),
        },
        Commands::Flake { command } => match command {
            FlakeCommands::Check => commands::flake::check(),
            FlakeCommands::Update { input } => commands::flake::update(&input),
            FlakeCommands::Fmt => commands::flake::fmt(),
        },
        Commands::Iso { command } => match command {
            IsoCommands::Build { config } => commands::iso::build(&config),
        },
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let result = match cli.command {
        Some(cmd) => dispatch(cmd),
        None => { Cli::command().print_help()?; println!(); Ok(()) }
    };
    if let Err(ref e) = result {
        output::error(&format!("{:#}", e));
        std::process::exit(1);
    }
    result
}
