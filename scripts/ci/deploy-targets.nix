{ flake }:
let
  f = builtins.getFlake flake;
  agents = f.clan.inventory.instances.cachix-deploy.roles.agent.machines;
in
builtins.filter (t: agents ? ${t.name}) (
  import ./targets.nix { inherit flake; }
)
