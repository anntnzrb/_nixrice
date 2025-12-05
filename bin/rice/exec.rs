use anyhow::{bail, Context, Result};
use std::process::Command;

use super::output;

pub fn run(cmd: &str, args: &[&str]) -> Result<()> {
    output::cmd(cmd, args);

    let status = Command::new(cmd)
        .args(args)
        .status()
        .with_context(|| format!("Failed to execute: {}", cmd))?;

    if !status.success() {
        bail!(
            "Command failed with exit code: {}",
            status.code().unwrap_or(-1)
        );
    }

    Ok(())
}

pub fn run_sudo(cmd: &str, args: &[&str]) -> Result<()> {
    let mut sudo_args = vec![cmd];
    sudo_args.extend(args);
    run("sudo", &sudo_args)
}
