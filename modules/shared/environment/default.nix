{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptEnabled';

  cfg = config.liberion.environment;
in
{
  options.liberion.environment = {
    # Shared baseline: the entrypoints wire this module into every host for the small
    # common toolset; leaf feature modules should remain opt-in.
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # tools
      git
      curl
      wget

      # archiving
      atool
      rar
      unrar-wrapper
      unzip
      zip

      # nix
      nh
    ];
  };
}
