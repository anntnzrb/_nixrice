{ lib, ... }:
let
  # nix-darwin agents use launchd.user.agents.<name>.serviceConfig.
  mkDarwinAgent =
    {
      name,
      serviceConfig,
      managedBy ? null,
    }:
    {
      launchd.user.agents.${name} = {
        inherit serviceConfig;
      }
      // lib.optionalAttrs (managedBy != null) { inherit managedBy; };
    };

in
{
  launchd.darwin.mkAgent = mkDarwinAgent;
}
