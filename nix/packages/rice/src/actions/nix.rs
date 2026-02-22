//! Nix maintenance workflows.

use anyhow::Result;
use std::path::PathBuf;

use crate::actions::core::{info, ok, run};

/// Clean local Nix caches and run `nh clean` routines.
pub(crate) fn nix_clean() -> Result<()> {
    #[cfg(test)]
    {
        nix_clean_with_home(None)
    }

    #[cfg(not(test))]
    {
        nix_clean_with_home(std::env::var_os("HOME").map(PathBuf::from))
    }
}

/// Clean local Nix caches and run `nh clean` routines for a provided home path.
pub(crate) fn nix_clean_with_home(home: Option<PathBuf>) -> Result<()> {
    info("Cleaning nix cache...");

    if let Some(home) = home {
        let cache_dir = home.join(".cache/nix");
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
