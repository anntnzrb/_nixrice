# AI agents source checkout

Import `inputs.self.homeModules.ai-agents` to prepare `~/src/agents` and keep its published branch current. This feature only manages the source checkout: it does not run agents sync, install its runtime, or modify harness homes.

The background job clones through Git when the destination is absent. An existing destination must be a normal Git checkout with the expected origin. Updates require a clean `main` branch, including no untracked files, and only fast-forward merges are allowed. Working branches, detached HEADs and local changes are left untouched. Divergence and unexpected destinations fail visibly instead of resetting user work.

The clone is prepared beside the destination and moved into place after completion. Network failures leave the destination absent so the next scheduled invocation can retry. Git authentication must already be available without an interactive prompt. No GitHub API polling is used.

On Linux the job runs as a user systemd service. It requires an active user manager; persistent operation after logout requires lingering configured separately. On Darwin it runs as a Home Manager launchd agent while the user's launchd session is available.

Inspect Linux failures with `journalctl --user -u ai-agents.service` and the schedule with `systemctl --user status ai-agents.timer`. On Darwin inspect the generated agent in `~/Library/LaunchAgents/` and its launchd status. This feature must not be scheduled against the same checkout by another updater.
