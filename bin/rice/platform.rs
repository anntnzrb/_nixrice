use anyhow::{bail, Result};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Platform {
    Linux,
    Darwin,
}

impl Platform {
    pub fn detect() -> Self {
        #[cfg(target_os = "linux")]
        return Platform::Linux;

        #[cfg(target_os = "macos")]
        return Platform::Darwin;

        #[cfg(not(any(target_os = "linux", target_os = "macos")))]
        compile_error!("Unsupported platform");
    }

    pub fn name(&self) -> &'static str {
        match self {
            Platform::Linux => "Linux",
            Platform::Darwin => "macOS",
        }
    }
}

pub fn require(required: Platform) -> Result<()> {
    let current = Platform::detect();
    if current != required {
        bail!(
            "This command requires {} (detected: {})",
            required.name(),
            current.name()
        );
    }
    Ok(())
}

pub fn hostname() -> Result<String> {
    let full = gethostname::gethostname().to_string_lossy().to_string();
    Ok(full.split('.').next().unwrap_or(&full).to_string())
}
