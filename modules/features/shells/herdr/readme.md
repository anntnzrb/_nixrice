# herdr

Terminal workspace manager for coding agents, imported in every home by
`modules/base/common/home.nix`.

- Package: `pkgs.unstable.herdr`. herdr finds the Nix profile binary on remote
  hosts, so every machine can serve and attach.
- Saved machines: on a machine-managed home, activation writes
  `$XDG_STATE_HOME/herdr/client/endpoints.json` with every non-archived peer
  (`lib.liberion.fleetPeers`). The target is the machine name, resolved by the
  fleet `Host` blocks from `network/sshd`. herdr refuses to replace that file
  through a symlink, so it is installed as a real file and overwritten on
  every switch: machines added with `herdr machine add` do not survive it.
  Profile IDs are an MD5 of target and session, so the selected machine
  stays valid across rebuilds.
- `config.toml` is left to herdr, which writes settings back to it.

Home Manager 26.11 ships `programs.herdr` (with `mutableSettings`); once the
flake follows that release, replace the package line with
`programs.herdr = { enable = true; package = pkgs.unstable.herdr; };`.
