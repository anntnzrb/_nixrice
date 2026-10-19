# Paseo

- Control the daemon through its service, never `paseo daemon start` or `stop`: a second supervisor takes `~/.paseo` and the service crash-loops.
- Enable providers, OMP included, in each host's **Settings → Providers**. `paseo daemon config set agents …` replaces every provider.
- With `liberion.ai.paseo.desktop` on a host that runs the service, turn off **Manage built-in daemon** in the app, or it replaces the service's daemon on a version mismatch.
- Connect directly over the tailnet (**Add host → Direct connection**, port 6767, SSL on); never pair through the relay.
- Never point a Paseo and a T3 agent at the same checkout at once. Paseo worktrees live in `~/.paseo/worktrees`, T3's in `~/.t3/worktrees`.
- Pick a metadata model the gateway serves under **Settings → Host → Metadata → Manual**.
- Do not install Paseo's skills from its settings; agents sync owns those directories.
