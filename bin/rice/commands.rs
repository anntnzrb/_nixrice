use anyhow::Result;

use super::exec::{run, run_sudo};
use super::output;
use super::platform::{self, Platform};

macro_rules! task {
    ($info:expr, $done:expr, $cmd:expr, $args:expr) => {{
        output::info($info);
        run($cmd, $args)?;
        output::success($done);
        Ok(())
    }};
    (sudo: $info:expr, $done:expr, $cmd:expr, $args:expr) => {{
        output::info($info);
        run_sudo($cmd, $args)?;
        output::success($done);
        Ok(())
    }};
}

pub mod nixos {
    use super::*;

    pub fn build() -> Result<()> {
        platform::require(Platform::Linux)?;
        task!("Building NixOS configuration...", "NixOS build complete",
              "nixos-rebuild", &["build", "--flake", ".#"])
    }

    pub fn boot() -> Result<()> {
        platform::require(Platform::Linux)?;
        build()?;
        task!("Setting boot configuration...", "Boot configuration set",
              "nixos-rebuild", &["boot", "--use-remote-sudo", "--flake", ".#"])
    }

    pub fn switch() -> Result<()> {
        platform::require(Platform::Linux)?;
        build()?;
        task!("Switching to new configuration...", "NixOS switch complete",
              "nixos-rebuild", &["switch", "--use-remote-sudo", "--flake", ".#"])
    }
}

pub mod darwin {
    use super::*;

    pub fn build() -> Result<()> {
        platform::require(Platform::Darwin)?;
        let hostname = platform::hostname()?;
        let flake_path = format!(".#darwinConfigurations.{}.system", hostname);
        output::info(&format!("Building Darwin configuration for {}...", hostname));
        run("nix", &["build", &flake_path])?;
        output::success("Darwin build complete");
        Ok(())
    }

    pub fn switch() -> Result<()> {
        platform::require(Platform::Darwin)?;
        build()?;
        let hostname = platform::hostname()?;
        let flake_ref = format!(".#{}", hostname);
        output::info("Switching to new configuration...");
        run_sudo("./result/sw/bin/darwin-rebuild", &["switch", "--flake", &flake_ref])?;
        output::success("Darwin switch complete");
        Ok(())
    }
}

pub mod home {
    use super::*;

    pub fn build(user: &str, host: &str) -> Result<()> {
        let flake_path = format!(".#homeConfigurations.{}@{}.activationPackage", user, host);
        output::info(&format!("Building home-manager configuration for {}@{}...", user, host));
        run("nix", &["build", &flake_path])?;
        output::success("Home-manager build complete");
        Ok(())
    }

    pub fn switch(user: &str, host: &str) -> Result<()> {
        build(user, host)?;
        task!("Activating home-manager configuration...", "Home-manager switch complete",
              "./result/activate", &[])
    }
}

pub mod nix {
    use super::*;

    pub fn clean() -> Result<()> {
        output::info("Cleaning nix cache...");
        let cache_dir = format!("{}/.cache/nix/", std::env::var("HOME").unwrap_or_default());
        let _ = std::fs::remove_dir_all(&cache_dir);
        run("nh", &["clean", "all"])?;
        run("nh", &["clean", "user"])?;
        output::success("Nix cleanup complete");
        Ok(())
    }

    pub fn optimise() -> Result<()> {
        clean()?;
        task!(sudo: "Optimizing nix store...", "Nix store optimized",
              "nix", &["store", "optimise"])
    }

    pub fn repair() -> Result<()> {
        optimise()?;
        task!(sudo: "Repairing nix store...", "Nix store repair complete",
              "nix-store", &["--verify", "--check-contents", "--repair"])
    }
}

pub mod flake {
    use super::*;

    pub fn check() -> Result<()> {
        task!("Checking flake...", "Flake check passed", "nix", &["flake", "check", "."])
    }

    pub fn update(input: &str) -> Result<()> {
        if input == "all" {
            output::info("Updating all flake inputs...");
            run("nix", &["flake", "update", "--commit-lock-file",
                "--option", "commit-lockfile-summary", "chore(flake): update lockfile"])?;
        } else {
            output::info(&format!("Updating flake input: {}...", input));
            run("nix", &["flake", "update", input])?;
            run("git", &["add", "flake.lock"])?;
            run("git", &["commit", "-m", &format!("chore(flake): update input ({})", input)])?;
        }
        output::success("Flake update complete");
        Ok(())
    }

    pub fn fmt() -> Result<()> {
        task!("Formatting and checking code...", "Format check complete",
              "pre-commit", &["run", "--all-files"])
    }
}

pub mod iso {
    use super::*;

    pub fn build(config: &str) -> Result<()> {
        let flake_path = format!(".#isoConfigurations.{}", config);
        output::info(&format!("Building ISO: {}...", config));
        run("nix", &["build", &flake_path])?;
        output::success("ISO build complete");
        Ok(())
    }
}
