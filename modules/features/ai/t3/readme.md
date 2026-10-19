# T3 Code

- Keep `providerInstances.claudeAgent.config.homePath` unset: it moves `CLAUDE_CONFIG_DIR` off the agents-managed `~/.claude`, dropping its hooks and Bash timeout cap.
- Check a new settings key against upstream `packages/contracts/src/settings.ts` first: T3 replaces an invalid `settings.json` with defaults.
- Browser and mobile follow-up behavior does not sync; set **Steer** by hand on every client and browser profile.
- Never pass `--tailscale` to T3 commands; publish through `liberion.network.tailscale.expose`.
- Moving to an older channel head needs `t3 update --allow-downgrade` by hand.
- With `liberion.ai.t3.desktop`, turn off **Settings → Connections → Local environment** so the app does not start a second server in `~/.t3`.
- Darwin: grant **Full Disk Access** and **Accessibility** once to `~/.t3/runtime/stable/t3`.
- Darwin: never run `t3 service restart` or `t3 service install` by hand; they re-enable T3's own job and can start a second server on the same data.
