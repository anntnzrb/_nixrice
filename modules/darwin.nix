# nix-darwin entrypoint: every `default.nix` under ./darwin plus the Home Manager bridge.
{
  lib,
  config,
  inputs,
  namespace,
  ...
}:
{
  imports = lib.${namespace}.fs.getDefaultFiles ./darwin ++ [
    inputs.home-manager.darwinModules.home-manager
    ./home-manager.nix
    ./nixpkgs.nix
  ];

  # liberion hosts own their defaults; clan-installed machines opt in
  clan.core.enableRecommendedDefaults = lib.mkDefault false;

  _module.args.host = config.clan.core.settings.machine.name;
}
