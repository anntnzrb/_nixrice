{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptEnabled';

  cfg = config.${namespace}.environment;
in
{
  options.${namespace}.environment = {
    # Shared baseline: Snowfall wires this module into every host for the small
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
