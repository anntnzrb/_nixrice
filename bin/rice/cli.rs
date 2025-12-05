use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "rice", version, about = "NixOS/Darwin configuration management")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// System configuration (platform-aware)
    System {
        #[command(subcommand)]
        command: SystemCommands,
    },
    /// Home Manager configuration
    Home {
        #[command(subcommand)]
        command: HomeCommands,
    },
    /// NixOS-specific commands
    Nixos {
        #[command(subcommand)]
        command: NixosCommands,
    },
    /// Darwin-specific commands
    Darwin {
        #[command(subcommand)]
        command: DarwinCommands,
    },
    /// Nix maintenance commands
    Nix {
        #[command(subcommand)]
        command: NixCommands,
    },
    /// Flake management commands
    Flake {
        #[command(subcommand)]
        command: FlakeCommands,
    },
    /// ISO generation commands
    Iso {
        #[command(subcommand)]
        command: IsoCommands,
    },
}

#[derive(Subcommand)]
pub enum SystemCommands {
    /// Build system configuration
    Build,
    /// Build and switch immediately
    Switch,
}

#[derive(Subcommand)]
pub enum HomeCommands {
    /// Build home-manager configuration
    Build {
        /// Username
        #[arg(default_value = "annt")]
        user: String,
        /// Hostname
        #[arg(default_value = "wsl")]
        host: String,
    },
    /// Build and activate home-manager configuration
    Switch {
        /// Username
        #[arg(default_value = "annt")]
        user: String,
        /// Hostname
        #[arg(default_value = "wsl")]
        host: String,
    },
}

#[derive(Subcommand)]
pub enum NixosCommands {
    /// Build NixOS configuration
    Build,
    /// Build and activate on next boot
    Boot,
    /// Build and switch immediately
    Switch,
}

#[derive(Subcommand)]
pub enum DarwinCommands {
    /// Build Darwin configuration
    Build,
    /// Build and switch immediately
    Switch,
}

#[derive(Subcommand)]
pub enum NixCommands {
    /// Clean nix cache and run cleanup
    Clean,
    /// Clean and optimize nix store
    Optimise,
    /// Clean, optimize and repair nix store
    Repair,
}

#[derive(Subcommand)]
pub enum FlakeCommands {
    /// Check flake validity
    Check,
    /// Update flake inputs (use "all" to update all)
    Update {
        /// Input to update (or "all" for all inputs)
        input: String,
    },
    /// Format and check code
    Fmt,
}

#[derive(Subcommand)]
pub enum IsoCommands {
    /// Build ISO configuration
    Build {
        /// ISO configuration name
        #[arg(default_value = "nomad")]
        config: String,
    },
}
