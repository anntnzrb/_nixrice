# starship

Prompt for zsh (and whatever other shell keeps Home Manager's integration).

- zsh init is `starship init zsh --print-full-init`, generated at build time and
  sourced (see `shells/zsh/readme.md`), so startup never forks starship
- `RPROMPT=` after init: there is no `right_format`, yet starship's init still
  sets `RPROMPT` to a second `starship prompt --right` call, one extra process
  per prompt for an empty string. Remove the line if a `right_format` is added

## Prompt behavior

Each prompt runs one `starship prompt` process. Inside a repo, `git_status` and
`git_branch` dominate its cost; every other module is negligible.

`git_commit`, `git_metrics` and `git_state` are disabled. Git runs with
`core.untrackedCache` and `feature.manyFiles` (`cli/git`).

Check with `starship timings` inside the directory in question.

## Rejected

- Disabling `git_status`: its repository status is worth keeping
- Raising `command_timeout`: it only hides slow modules, it never speeds them up
