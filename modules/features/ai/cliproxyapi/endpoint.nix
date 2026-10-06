# Tailnet /v1 URL of the gateway for clients; `domain` is the Clan domain.
domain:
"http://solna.${domain}:${
  toString (import ./settings.nix { stateDir = ""; }).port
}/v1"
