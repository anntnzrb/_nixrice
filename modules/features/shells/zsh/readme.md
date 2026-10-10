# zsh

Interactive zsh, tuned for startup time. Budget: ~50 ms for `zsh -i -c exit` on
beirut (M4). Before this layout it was ~1 s (measured 2026-09-28).

- `darwin.nix`: system zsh, with the nix-darwin interactive init turned off
  (`enableGlobalCompInit`, `enableBashCompletion`, `promptInit`)
- `home.nix`: Home Manager zsh, owns completion init, history, plugins

## Rules

- One `compinit`, in Home Manager. nix-darwin's global one ran first with a
  different `fpath`; both shared `$ZDOTDIR/.zcompdump`, each saw a file-count
  mismatch and rebuilt it on every shell (~800 ms each)
- No forks at startup. Tool init goes through a build-time file, never
  `eval "$(tool init zsh)"` (~3-5 ms per fork; `brew shellenv` 24 ms). Done in
  `cli/zoxide`, `cli/fzf`, `cli/direnv`, `shells/starship` and
  `darwin/homebrew`: disable the Home Manager `enableZshIntegration`, generate
  the script with `pkgs.runCommand`, `source` it with the same guard and
  `lib.mkOrder` Home Manager used. New integrations follow the same pattern
- `completionInit` caches the dump keyed on `$ZSH_VERSION`, `${fpath:A}` and
  the mtime of every `fpath` directory outside `/nix/store` (Homebrew, OrbStack)
  in `.zcompdump.key`. `:A` resolves the profile symlinks to store paths without
  forking, so a new generation invalidates the cache on its own; `zstat`
  catches `brew install` dropping a new completion. Hit: `compinit -C` (no
  `compaudit`, no fpath scan). Miss: rebuild + `zcompile`
- `ZSH_AUTOSUGGEST_MANUAL_REBIND`: zsh-autosuggestions otherwise rebinds every
  widget in `precmd` (~7 ms per prompt). Consequence: widgets defined after
  startup are not wrapped until `_zsh_autosuggest_bind_widgets` runs

## Measure

```sh
# startup, 20-run average
zsh -f -c 'zmodload zsh/datetime; s=$EPOCHREALTIME; repeat 20 zsh -i -c exit; printf "%.1fms\n" $(( (EPOCHREALTIME-s)*50 ))'

# where startup goes
PS4='+%D{%s.%.} %N:%i> ' zsh -ixc exit 2>/tmp/trace.log

# per-prompt cost of each precmd hook
zsh -i -c 'zmodload zsh/datetime; for f in $precmd_functions; do s=$EPOCHREALTIME; repeat 10 $f; printf "%-35s %.2fms\n" $f $(( (EPOCHREALTIME-s)*100 )); done'

# why compinit rebuilt the dump
zsh -i -c 'compinit -w'
```

Use `$EPOCHREALTIME`, not `perl`/`date` wrappers: those add ~10 ms per sample.
The first shell after a switch rebuilds the dump once (~0.4 s); that is expected.
