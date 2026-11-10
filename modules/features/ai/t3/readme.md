# T3 Code

- Browser and mobile follow-up behavior does not sync; set **Steer** by hand on every client and browser profile.
- Never pass `--tailscale` to T3 commands; publish through `liberion.network.tailscale.expose`.
- Darwin: grant **Full Disk Access** and **Accessibility** once to `~/.t3/runtime/stable/t3`.
- Darwin: never run `t3 service restart` or `t3 service install` by hand; they re-enable T3's own job and can start a second server on the same data.
