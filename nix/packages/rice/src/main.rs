//! Binary entrypoint for the `rice` CLI.

use anyhow as _;
use clap as _;
use hostname as _;

/// Parse process arguments and execute the CLI flow.
#[cfg(not(test))]
fn main() {
    rice::run_main();
}

/// Test-only binary entrypoint.
#[cfg(test)]
const fn main() {
    use rice as _;
}
