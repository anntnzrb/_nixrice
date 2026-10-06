# Git source checkouts

`lib.liberion.gitCheckout { name, description, repository, destination, branch, update ? null }` returns a Home Manager module that prepares a source checkout under the home directory and keeps it current. Without `update` it only manages the checkout: it never builds, switches, deploys, or runs project tooling.

`update` hands the checkout to project tooling instead. It is a function of `{ config, pkgs }` returning a package whose main program receives the checkout path. After the clone exists and its `origin` is verified, the job executes that program on every run instead of fetching; the program owns fetching, branch policy, and reconciliation. A checkout must have exactly one updater, so the tooling must not schedule its own.

Without `update`, the background job clones through Git when the destination is absent. An existing destination must be a normal Git checkout whose `origin` equals `repository` exactly. Updates require the configured branch to be checked out with a clean tree, including no untracked files, and only fast-forward merges are allowed. Working branches, detached HEADs, local changes and unpushed commits are left untouched. Divergence and unexpected destinations fail visibly instead of resetting user work. The clone and origin checks apply with `update` too.

The clone is prepared beside the destination and moved into place after completion. Network failures leave the destination absent so the next scheduled invocation can retry. Git authentication must already be available without an interactive prompt. No GitHub API polling is used.

On Linux the job runs as a user systemd service and timer named after `name`, every five minutes, at idle CPU and I/O priority, with a 20-minute start timeout to fit a project reconcile. It requires an active user manager; persistent operation after logout requires lingering configured separately. On Darwin it runs as a Home Manager launchd agent while the user's launchd session is available.

Inspect Linux failures with `journalctl --user -u <name>.service` and the schedule with `systemctl --user status <name>.timer`. On Darwin inspect the generated agent in `~/Library/LaunchAgents/` and its launchd status. A checkout must not be scheduled by more than one updater.
