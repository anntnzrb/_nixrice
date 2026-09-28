# homebrew

Homebrew on darwin, installed and pinned by nix-homebrew; casks and Mac App
Store apps picked per machine through `liberion.homebrew.apps`.

## zsh environment

nix-homebrew's zsh integration (`eval "$(brew shellenv)"`, ~24 ms per shell) is
off. `programs.zsh.interactiveShellInit` exports the same variables as static
text built from `homebrew.prefix` and `nix-homebrew.prefixes.<prefix>.library`.

After a Homebrew upgrade, compare with the live output; the static block must
match it line for line:

```sh
brew shellenv zsh
```

Bash and fish keep nix-homebrew's integration.
