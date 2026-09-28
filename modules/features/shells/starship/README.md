# starship

Prompt for zsh (and whatever other shell keeps Home Manager's integration).

- zsh init is `starship init zsh --print-full-init`, generated at build time and
  sourced (see `shells/zsh/README.md`), so startup never forks starship
- `RPROMPT=` after init: there is no `right_format`, yet starship's init still
  sets `RPROMPT` to a second `starship prompt --right` call, one extra process
  per prompt for an empty string. Remove the line if a `right_format` is added

## Cost per prompt

One `starship prompt` process, ~4 ms outside git. Inside a repo the git modules
dominate (measured on this repo, 2026-09-28):

| Module | Time |
| --- | --- |
| `git_status` | ~10 ms |
| `git_branch` | ~8 ms |
| everything else | <1 ms each |

`git_commit`, `git_metrics` and `git_state` are disabled. Git runs with
`core.untrackedCache` and `feature.manyFiles` (`cli/git`).

Check with `starship timings` inside the directory in question.

## Rejected

- Disabling `git_status`: ~10 ms back, but it is the one piece of the prompt
  worth reading
- Raising `command_timeout`: it only hides slow modules, it never speeds them up
