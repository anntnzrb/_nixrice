# CLIProxyAPI

- Never expose the backend through Funnel; it has no authentication. Only `auth-gateway.py` is public.
- Provision `secrets.json` and the OAuth files in `auth/` by hand, owned by `cliproxyapi`, mode `0600`. The service does not start without `secrets.json`.
- Every `.json` in `auth/` is treated as a credential; put nothing else there.
