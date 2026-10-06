# AI agents source checkout

Import `inputs.self.homeModules.ai-agents` to prepare `~/src/agents` and run `sync update` from it every five minutes. Sync fast-forwards a clean `main` and reconciles a new commit; this module is the only scheduler, and agents sync installs no updater of its own. The job uses the installed sync runtime, falling back to `uv` from the checkout before the first sync has installed one. Scheduling and inspection: `lib/git-checkout.md`.
