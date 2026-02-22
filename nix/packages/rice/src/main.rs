//! CLI entrypoint and command orchestration for the `rice` tool.

use anyhow::{Result, bail};
use clap::{Parser, Subcommand};
use std::env;
use std::ffi::OsString;
#[cfg(unix)]
use std::os::unix::process::ExitStatusExt;
use std::path::PathBuf;
use std::process::Command;

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

/// Supported runtime platforms.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Platform {
    /// Apple Darwin systems.
    Darwin,
    /// Linux systems.
    Linux,
}

/// Immutable description of one executable task.
#[derive(Clone, Copy, Debug)]
struct Task {
    /// Message shown before command execution.
    info: &'static str,
    /// Process command and arguments.
    cmd: &'static [&'static str],
    /// Success message shown after execution.
    ok: &'static str,
    /// Whether command should run through `sudo`.
    sudo: bool,
    /// Optional platform restriction for this task.
    platform: Option<Platform>,
}

/// Linux task that builds system configuration.
const NIXOS_BUILD: Task = Task {
    info: "Building NixOS...",
    cmd: &["nixos-rebuild", "build", "--flake", ".#"],
    ok: "NixOS build complete",
    sudo: false,
    platform: Some(Platform::Linux),
};

/// Linux task that stages next boot configuration.
const NIXOS_BOOT: Task = Task {
    info: "Setting boot...",
    cmd: &["nixos-rebuild", "boot", "--sudo", "--flake", ".#"],
    ok: "Boot set",
    sudo: false,
    platform: Some(Platform::Linux),
};

/// Linux task that switches active system configuration.
const NIXOS_SWITCH: Task = Task {
    info: "Switching...",
    cmd: &["nixos-rebuild", "switch", "--sudo", "--flake", ".#"],
    ok: "NixOS switch complete",
    sudo: false,
    platform: Some(Platform::Linux),
};

/// Darwin task that builds host configuration output.
const DARWIN_BUILD: Task = Task {
    info: "Building Darwin for {host}...",
    cmd: &["nix", "build", ".#darwinConfigurations.{host}.system"],
    ok: "Darwin build complete",
    sudo: false,
    platform: Some(Platform::Darwin),
};

/// Darwin task that switches active configuration.
const DARWIN_SWITCH: Task = Task {
    info: "Switching...",
    cmd: &[
        "./result/sw/bin/darwin-rebuild",
        "switch",
        "--flake",
        ".#{host}",
    ],
    ok: "Darwin switch complete",
    sudo: true,
    platform: Some(Platform::Darwin),
};

/// Task that optimizes the local Nix store.
const NIX_OPTIMISE: Task = Task {
    info: "Optimizing nix store...",
    cmd: &["nix", "store", "optimise"],
    ok: "Nix store optimized",
    sudo: true,
    platform: None,
};

/// Task that verifies and repairs the local Nix store.
const NIX_REPAIR: Task = Task {
    info: "Repairing nix store...",
    cmd: &["nix-store", "--verify", "--check-contents", "--repair"],
    ok: "Nix store repaired",
    sudo: true,
    platform: None,
};

/// Task that checks flake evaluation and checks.
const FLAKE_CHECK: Task = Task {
    info: "Checking flake...",
    cmd: &["nix", "flake", "check", "."],
    ok: "Flake check passed",
    sudo: false,
    platform: None,
};

/// Task that runs repository formatting hooks.
const FLAKE_FMT: Task = Task {
    info: "Formatting...",
    cmd: &["pre-commit", "run", "--all-files"],
    ok: "Format complete",
    sudo: false,
    platform: None,
};

/// Top-level command line parser.
#[derive(Parser, Debug)]
#[command(
    name = "rice",
    about = "NixOS/Darwin configuration management",
    arg_required_else_help = true,
    disable_help_subcommand = true
)]
struct Cli {
    /// Top-level selected command group.
    #[command(subcommand)]
    command: Commands,
}

/// Top-level command groups.
#[derive(Subcommand, Debug)]
enum Commands {
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
enum SystemCommands {
    /// Build the current platform configuration.
    #[command(about = "Build system configuration")]
    Build,
    /// Build then switch the current platform configuration.
    #[command(about = "Build and switch immediately")]
    Switch,
}

/// Subcommands for the home group.
#[derive(Subcommand, Debug)]
enum HomeCommands {
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
enum NixosCommands {
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
enum DarwinCommands {
    /// Build Darwin configuration.
    #[command(about = "Build Darwin configuration")]
    Build,
    /// Build and switch Darwin configuration.
    #[command(about = "Build and switch immediately")]
    Switch,
}

/// Subcommands for maintenance operations.
#[derive(Subcommand, Debug)]
enum NixCommands {
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
enum FlakeCommands {
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

/// Detect the current platform at compile target level.
const fn current_platform() -> Platform {
    if cfg!(target_os = "macos") {
        Platform::Darwin
    } else {
        Platform::Linux
    }
}

/// Read hostname and return only the short segment before first dot.
fn host_shortname() -> String {
    let hostname = hostname::get().unwrap_or_else(|_| OsString::from("unknown"));
    let hostname = hostname.to_string_lossy();
    hostname.split('.').next().unwrap_or("unknown").to_string()
}

/// Print a success message line.
fn ok(msg: &str) {
    println!("{GREEN}✓{RESET} {msg}");
}

/// Print an error message line.
fn err(msg: &str) {
    eprintln!("{RED}✗{RESET} {msg}");
}

/// Print an informational message line.
fn info(msg: &str) {
    println!("{BLUE}→{RESET} {msg}");
}

/// Replace task context tokens in a template string.
fn with_context(template: &str, host: &str) -> String {
    template.replace(HOST_TOKEN, host)
}

/// Ensure a command is running on a required platform.
fn require_platform(required: Platform, current: Platform) -> Result<()> {
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
fn run(mut cmd: Vec<String>, sudo: bool) -> Result<()> {
    if sudo {
        cmd.insert(0, "sudo".to_string());
    }

    println!("{DIM}$ {}{RESET}", cmd.join(" "));

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
fn exec_task(task: Task, host: &str, current: Platform) -> Result<()> {
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

/// Build the requested home activation package.
fn home_build(user: &str, host: &str) -> Result<()> {
    info(&format!("Building home-manager for {user}@{host}..."));
    run(
        vec![
            "nix".to_string(),
            "build".to_string(),
            format!(".#homeConfigurations.{user}@{host}.activationPackage"),
        ],
        false,
    )?;
    ok("Home-manager build complete");
    Ok(())
}

/// Build and activate the requested home profile.
fn home_switch(user: &str, host: &str) -> Result<()> {
    home_build(user, host)?;
    info("Activating home-manager...");
    run(vec!["./result/activate".to_string()], false)?;
    ok("Home-manager switch complete");
    Ok(())
}

/// Clean local Nix caches and run `nh clean` routines.
fn nix_clean() -> Result<()> {
    info("Cleaning nix cache...");

    if let Some(home) = env::var_os("HOME") {
        let cache_dir = PathBuf::from(home).join(".cache/nix");
        let _ = std::fs::remove_dir_all(cache_dir);
    }

    run(
        vec!["nh".to_string(), "clean".to_string(), "all".to_string()],
        false,
    )?;
    run(
        vec!["nh".to_string(), "clean".to_string(), "user".to_string()],
        false,
    )?;
    ok("Nix cleanup complete");
    Ok(())
}

/// Update one flake input or all inputs and commit lockfile changes when needed.
fn flake_update(name: &str) -> Result<()> {
    if name == "all" {
        info("Updating all flake inputs...");
        run(
            vec![
                "nix".to_string(),
                "flake".to_string(),
                "update".to_string(),
                "--commit-lock-file".to_string(),
                "--option".to_string(),
                "commit-lockfile-summary".to_string(),
                "chore(flake): update lockfile".to_string(),
            ],
            false,
        )?;
        ok("Flake update complete");
        return Ok(());
    }

    info(&format!("Updating flake input: {name}..."));
    run(
        vec![
            "nix".to_string(),
            "flake".to_string(),
            "update".to_string(),
            name.to_string(),
        ],
        false,
    )?;
    run(
        vec![
            "git".to_string(),
            "add".to_string(),
            "flake.lock".to_string(),
        ],
        false,
    )?;
    run(
        vec![
            "git".to_string(),
            "commit".to_string(),
            "-m".to_string(),
            format!("chore(flake): update input ({name})"),
        ],
        false,
    )?;
    ok("Flake update complete");
    Ok(())
}

/// Route parsed CLI commands to concrete task handlers.
fn run_cli(cli: Cli) -> Result<()> {
    let host = host_shortname();
    let current = current_platform();

    match cli.command {
        Commands::System { command } => match command {
            SystemCommands::Build => {
                exec_task(
                    if current == Platform::Darwin {
                        DARWIN_BUILD
                    } else {
                        NIXOS_BUILD
                    },
                    &host,
                    current,
                )?;
            }
            SystemCommands::Switch => {
                if current == Platform::Darwin {
                    exec_task(DARWIN_BUILD, &host, current)?;
                    exec_task(DARWIN_SWITCH, &host, current)?;
                } else {
                    exec_task(NIXOS_BUILD, &host, current)?;
                    exec_task(NIXOS_SWITCH, &host, current)?;
                }
            }
        },
        Commands::Home { command } => match command {
            HomeCommands::Build { user, host } => home_build(&user, &host)?,
            HomeCommands::Switch { user, host } => home_switch(&user, &host)?,
        },
        Commands::Nixos { command } => match command {
            NixosCommands::Build => exec_task(NIXOS_BUILD, &host, current)?,
            NixosCommands::Boot => exec_task(NIXOS_BOOT, &host, current)?,
            NixosCommands::Switch => exec_task(NIXOS_SWITCH, &host, current)?,
        },
        Commands::Darwin { command } => match command {
            DarwinCommands::Build => exec_task(DARWIN_BUILD, &host, current)?,
            DarwinCommands::Switch => exec_task(DARWIN_SWITCH, &host, current)?,
        },
        Commands::Nix { command } => match command {
            NixCommands::Optimise => exec_task(NIX_OPTIMISE, &host, current)?,
            NixCommands::Repair => exec_task(NIX_REPAIR, &host, current)?,
            NixCommands::Clean => nix_clean()?,
        },
        Commands::Flake { command } => match command {
            FlakeCommands::Check => exec_task(FLAKE_CHECK, &host, current)?,
            FlakeCommands::Fmt => exec_task(FLAKE_FMT, &host, current)?,
            FlakeCommands::Update { name } => flake_update(&name)?,
        },
    }

    Ok(())
}

/// Parse arguments and execute command flow.
fn main() {
    let cli = Cli::parse();
    if let Err(error) = run_cli(cli) {
        err(&error.to_string());
        std::process::exit(1);
    }
}

/// Unit tests for parser behavior and helper routines.
#[cfg(test)]
mod tests;
