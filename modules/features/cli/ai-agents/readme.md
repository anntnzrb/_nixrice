# AI agents source checkout

Import `inputs.self.homeModules.ai-agents` to prepare `~/src/agents` and run `sync update` from it every five minutes. Sync fast-forwards a clean `main` and reconciles a new commit; this module is the only scheduler, and agents sync installs no updater of its own. The job uses the installed sync runtime, falling back to `uv` from the checkout before the first sync has installed one. Scheduling and inspection: `lib/git-checkout.md`.

`agents-refresh-packages` runs `sync job refresh-packages` every 15 minutes and 5 minutes after login: it installs newer harness and tool releases into the package caches, so a launch only execs the cached version and never waits on the network. Callers with a short budget depend on that, such as T3 Code, whose provider health check gives `claude --version` 4 seconds.
