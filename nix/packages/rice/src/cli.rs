//! Command line parser definitions.

use clap::{Parser, Subcommand};

/// Top-level command line parser.
#[derive(Parser, Debug)]
#[command(
    name = "rice",
    about = "NixOS/Darwin configuration management",
    arg_required_else_help = true,
    disable_help_subcommand = true
)]
pub(crate) struct Cli {
    /// Top-level selected command group.
    #[command(subcommand)]
    pub(crate) command: Commands,
}

/// Top-level command groups.
#[derive(Subcommand, Debug)]
pub(crate) enum Commands {
    /// System operations.
    #[command(about = "System configuration", arg_required_else_help = true)]
    System {
        /// System subcommand.
        #[command(subcommand)]
        command: SystemCommands,
    },
    /// Home operations.
    #[command(about = "Home Manager", arg_required_else_help = true)]
    Home {
        /// Home subcommand.
        #[command(subcommand)]
        command: HomeCommands,
    },
    /// Linux operations.
    #[command(about = "NixOS commands", arg_required_else_help = true)]
    Nixos {
        /// Linux subcommand.
        #[command(subcommand)]
        command: NixosCommands,
    },
    /// Darwin operations.
    #[command(about = "Darwin commands", arg_required_else_help = true)]
    Darwin {
        /// Darwin subcommand.
        #[command(subcommand)]
        command: DarwinCommands,
    },
    /// Store maintenance operations.
    #[command(about = "Nix maintenance", arg_required_else_help = true)]
    Nix {
        /// Maintenance subcommand.
        #[command(subcommand)]
        command: NixCommands,
    },
    /// Flake workflow operations.
    #[command(about = "Flake management", arg_required_else_help = true)]
    Flake {
        /// Flake subcommand.
        #[command(subcommand)]
        command: FlakeCommands,
    },
}

/// Subcommands for the system group.
#[derive(Subcommand, Debug)]
pub(crate) enum SystemCommands {
    /// Build the current platform configuration.
    #[command(about = "Build system configuration")]
    Build,
    /// Build then switch the current platform configuration.
    #[command(about = "Build and switch immediately")]
    Switch,
}

/// Subcommands for the home group.
#[derive(Subcommand, Debug)]
pub(crate) enum HomeCommands {
    /// Build a home configuration.
    #[command(about = "Build home-manager configuration")]
    Build {
        /// Home username segment.
        #[arg(default_value = "annt")]
        user: String,
        /// Home host segment.
        #[arg(default_value = "wsl")]
        host: String,
    },
    /// Build and activate a home configuration.
    #[command(about = "Build and activate home-manager configuration")]
    Switch {
        /// Home username segment.
        #[arg(default_value = "annt")]
        user: String,
        /// Home host segment.
        #[arg(default_value = "wsl")]
        host: String,
    },
}

/// Subcommands for Linux operations.
#[derive(Subcommand, Debug)]
pub(crate) enum NixosCommands {
    /// Build Linux configuration.
    #[command(about = "Build NixOS configuration")]
    Build,
    /// Build Linux configuration for next boot.
    #[command(about = "Build and activate on next boot")]
    Boot,
    /// Build and switch Linux configuration.
    #[command(about = "Build and switch immediately")]
    Switch,
}

/// Subcommands for Darwin operations.
#[derive(Subcommand, Debug)]
pub(crate) enum DarwinCommands {
    /// Build Darwin configuration.
    #[command(about = "Build Darwin configuration")]
    Build,
    /// Build and switch Darwin configuration.
    #[command(about = "Build and switch immediately")]
    Switch,
}

/// Subcommands for maintenance operations.
#[derive(Subcommand, Debug)]
pub(crate) enum NixCommands {
    /// Optimize the Nix store.
    #[command(about = "Optimize nix store")]
    Optimise,
    /// Repair the Nix store.
    #[command(about = "Repair nix store")]
    Repair,
    /// Remove local cache and run cleanups.
    #[command(about = "Clean nix cache and run cleanup")]
    Clean,
}

/// Subcommands for flake operations.
#[derive(Subcommand, Debug)]
pub(crate) enum FlakeCommands {
    /// Run flake checks.
    #[command(about = "Check flake validity")]
    Check,
    /// Run formatting hooks.
    #[command(about = "Format and check code")]
    Fmt,
    /// Update one or all flake inputs.
    #[command(about = "Update flake inputs (use \"all\" to update all)")]
    Update {
        /// Input name or `all`.
        #[arg(help = "Input to update (or \"all\")")]
        name: String,
    },
}
