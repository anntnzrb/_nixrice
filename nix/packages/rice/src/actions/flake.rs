//! Flake update workflow logic.

use anyhow::Result;

use crate::actions::core::{info, ok, run};

/// Update one flake input or all inputs and commit lockfile changes when needed.
pub(crate) fn flake_update(name: &str) -> Result<()> {
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
