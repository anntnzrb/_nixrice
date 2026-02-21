use clap::{Parser, Subcommand};
use std::env;
use std::ffi::OsString;
#[cfg(unix)]
use std::os::unix::process::ExitStatusExt;
use std::path::PathBuf;
use std::process::Command;
use thiserror::Error;

const GREEN: &str = "\x1b[1;32m";
const RED: &str = "\x1b[1;31m";
const BLUE: &str = "\x1b[1;34m";
const DIM: &str = "\x1b[2m";
const RESET: &str = "\x1b[0m";
const HOST_TOKEN: &str = "{host}";

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Platform {
    Darwin,
    Linux,
}

#[derive(Clone, Copy, Debug)]
struct Task {
    info: &'static str,
    cmd: &'static [&'static str],
    ok: &'static str,
    sudo: bool,
    platform: Option<Platform>,
}

const NIXOS_BUILD: Task = Task {
    info: "Building NixOS...",
    cmd: &["nixos-rebuild", "build", "--flake", ".#"],
    ok: "NixOS build complete",
    sudo: false,
    platform: Some(Platform::Linux),
};

const NIXOS_BOOT: Task = Task {
    info: "Setting boot...",
    cmd: &["nixos-rebuild", "boot", "--sudo", "--flake", ".#"],
    ok: "Boot set",
    sudo: false,
    platform: Some(Platform::Linux),
};

const NIXOS_SWITCH: Task = Task {
    info: "Switching...",
    cmd: &["nixos-rebuild", "switch", "--sudo", "--flake", ".#"],
    ok: "NixOS switch complete",
    sudo: false,
    platform: Some(Platform::Linux),
};

const DARWIN_BUILD: Task = Task {
    info: "Building Darwin for {host}...",
    cmd: &["nix", "build", ".#darwinConfigurations.{host}.system"],
    ok: "Darwin build complete",
    sudo: false,
    platform: Some(Platform::Darwin),
};

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

const NIX_OPTIMISE: Task = Task {
    info: "Optimizing nix store...",
    cmd: &["nix", "store", "optimise"],
    ok: "Nix store optimized",
    sudo: true,
    platform: None,
};

const NIX_REPAIR: Task = Task {
    info: "Repairing nix store...",
    cmd: &["nix-store", "--verify", "--check-contents", "--repair"],
    ok: "Nix store repaired",
    sudo: true,
    platform: None,
};

const FLAKE_CHECK: Task = Task {
    info: "Checking flake...",
    cmd: &["nix", "flake", "check", "."],
    ok: "Flake check passed",
    sudo: false,
    platform: None,
};

const FLAKE_FMT: Task = Task {
    info: "Formatting...",
    cmd: &["pre-commit", "run", "--all-files"],
    ok: "Format complete",
    sudo: false,
    platform: None,
};

#[derive(Parser, Debug)]
#[command(
    name = "rice",
    about = "NixOS/Darwin configuration management",
    arg_required_else_help = true,
    disable_help_subcommand = true
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand, Debug)]
enum Commands {
    #[command(about = "System configuration", arg_required_else_help = true)]
    System {
        #[command(subcommand)]
        command: SystemCommands,
    },
    #[command(about = "Home Manager", arg_required_else_help = true)]
    Home {
        #[command(subcommand)]
        command: HomeCommands,
    },
    #[command(about = "NixOS commands", arg_required_else_help = true)]
    Nixos {
        #[command(subcommand)]
        command: NixosCommands,
    },
    #[command(about = "Darwin commands", arg_required_else_help = true)]
    Darwin {
        #[command(subcommand)]
        command: DarwinCommands,
    },
    #[command(about = "Nix maintenance", arg_required_else_help = true)]
    Nix {
        #[command(subcommand)]
        command: NixCommands,
    },
    #[command(about = "Flake management", arg_required_else_help = true)]
    Flake {
        #[command(subcommand)]
        command: FlakeCommands,
    },
}

#[derive(Subcommand, Debug)]
enum SystemCommands {
    #[command(about = "Build system configuration")]
    Build,
    #[command(about = "Build and switch immediately")]
    Switch,
}

#[derive(Subcommand, Debug)]
enum HomeCommands {
    #[command(about = "Build home-manager configuration")]
    Build {
        #[arg(default_value = "annt")]
        user: String,
        #[arg(default_value = "wsl")]
        host: String,
    },
    #[command(about = "Build and activate home-manager configuration")]
    Switch {
        #[arg(default_value = "annt")]
        user: String,
        #[arg(default_value = "wsl")]
        host: String,
    },
}

#[derive(Subcommand, Debug)]
enum NixosCommands {
    #[command(about = "Build NixOS configuration")]
    Build,
    #[command(about = "Build and activate on next boot")]
    Boot,
    #[command(about = "Build and switch immediately")]
    Switch,
}

#[derive(Subcommand, Debug)]
enum DarwinCommands {
    #[command(about = "Build Darwin configuration")]
    Build,
    #[command(about = "Build and switch immediately")]
    Switch,
}

#[derive(Subcommand, Debug)]
enum NixCommands {
    #[command(about = "Optimize nix store")]
    Optimise,
    #[command(about = "Repair nix store")]
    Repair,
    #[command(about = "Clean nix cache and run cleanup")]
    Clean,
}

#[derive(Subcommand, Debug)]
enum FlakeCommands {
    #[command(about = "Check flake validity")]
    Check,
    #[command(about = "Format and check code")]
    Fmt,
    #[command(about = "Update flake inputs (use \"all\" to update all)")]
    Update {
        #[arg(help = "Input to update (or \"all\")")]
        name: String,
    },
}

#[derive(Debug, Error)]
enum AppError {
    #[error("Requires {0}")]
    Platform(&'static str),
    #[error("command failed: {0}")]
    CommandFailed(String),
    #[error("{0}")]
    Io(#[from] std::io::Error),
}

const fn current_platform() -> Platform {
    if cfg!(target_os = "macos") {
        Platform::Darwin
    } else {
        Platform::Linux
    }
}

fn host_shortname() -> String {
    let hostname = hostname::get().unwrap_or_else(|_| OsString::from("unknown"));
    let hostname = hostname.to_string_lossy();
    hostname.split('.').next().unwrap_or("unknown").to_string()
}

fn ok(msg: &str) {
    println!("{GREEN}✓{RESET} {msg}");
}

fn err(msg: &str) {
    eprintln!("{RED}✗{RESET} {msg}");
}

fn info(msg: &str) {
    println!("{BLUE}→{RESET} {msg}");
}

fn with_context(template: &str, host: &str) -> String {
    template.replace(HOST_TOKEN, host)
}

fn require_platform(required: Platform, current: Platform) -> Result<(), AppError> {
    if required == current {
        return Ok(());
    }

    let name = match required {
        Platform::Darwin => "macOS",
        Platform::Linux => "Linux",
    };
    err(&format!("Requires {name}"));
    Err(AppError::Platform(name))
}

fn run(mut cmd: Vec<String>, sudo: bool) -> Result<(), AppError> {
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

    Err(AppError::CommandFailed(format!(
        "{} (exit: {code})",
        cmd.join(" ")
    )))
}

fn exec_task(task: Task, host: &str, current: Platform) -> Result<(), AppError> {
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

fn home_build(user: &str, host: &str) -> Result<(), AppError> {
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

fn home_switch(user: &str, host: &str) -> Result<(), AppError> {
    home_build(user, host)?;
    info("Activating home-manager...");
    run(vec!["./result/activate".to_string()], false)?;
    ok("Home-manager switch complete");
    Ok(())
}

fn nix_clean() -> Result<(), AppError> {
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

fn flake_update(name: &str) -> Result<(), AppError> {
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

fn run_cli(cli: Cli) -> Result<(), AppError> {
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

fn main() {
    let cli = Cli::parse();
    if let Err(error) = run_cli(cli) {
        if !matches!(error, AppError::Platform(_)) {
            err(&error.to_string());
        }
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests;
