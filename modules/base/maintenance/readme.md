# Maintenance

Every home runs one nightly `maintenance` job (03:00–05:00, idle priority; a systemd user timer on Linux, a launchd agent on Darwin). It runs each `liberion.maintenance.tasks.<name>.command` in name order, logs one line per task, keeps going past a failed task, and exits nonzero if any failed.

Every home registers these tasks, which trim re-downloadable caches and scratch:

- `uv` (from `cli/uv`): `uv cache prune`, which keeps entries in use and skips a locked cache.
- `bun` (from `cli/bun`): empties `~/.bun/install/cache` and `$XDG_CACHE_HOME/.bun/install/cache`. Bun moved its default cache, and `bun pm cache rm` clears only the current one.
- `scratch`: `scratch.py` removes top-level `/tmp` entries this user owns that nothing touched for 7 days. Sockets, `*.lock` flock targets, and runtime prefixes such as `tmux-`, `systemd-private-` and `nix-` are kept.

A feature that leaves its own cache adds a task beside its configuration:

```nix
{ liberion.maintenance.tasks.cargo.command = [ "cargo" "cache" "--autoclean" ]; }
```

A task owns its safety rules. The npm task in `features/cli/ai-agents` runs `sync job npm-cache-clean`, which skips while an agents launcher holds an install lock.

Run now and inspect: `systemctl --user start maintenance.service` and `journalctl --user -u maintenance.service` on Linux; `launchctl kickstart gui/$(id -u)/org.nix-community.home.maintenance` and `~/Library/Logs/maintenance.log` on Darwin.

Test the scratch rules: `checks.python` (`just check`); in the dev shell, `pytest modules/base/maintenance/tests`.
