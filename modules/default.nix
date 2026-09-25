# NixOS entrypoint: every `default.nix` under ./nixos plus the Home Manager bridge.
{ lib, inputs, ... }: {
  imports =
    lib.liberion.fs.getDefaultFiles ./nixos
    ++ lib.liberion.fs.getDefaultFiles ./shared
    ++ [
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      ./nixpkgs.nix
    ];

  # liberion hosts own their defaults; clan-installed machines opt in
  clan.core.enableRecommendedDefaults = lib.mkDefault false;

  # the channel tarball behind clan-core/nixpkgs ships programs.sqlite, which
  # would switch command-not-found on; keep it off as before
  programs.command-not-found.enable = lib.mkDefault false;
}
