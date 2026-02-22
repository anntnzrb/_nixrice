//! Home-manager related workflows.

use anyhow::Result;

use crate::actions::core::{info, ok, run};

/// Build the requested home activation package.
pub(crate) fn home_build(user: &str, host: &str) -> Result<()> {
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
pub(crate) fn home_switch(user: &str, host: &str) -> Result<()> {
    home_build(user, host)?;
    info("Activating home-manager...");
    run(vec!["./result/activate".to_string()], false)?;
    ok("Home-manager switch complete");
    Ok(())
}
