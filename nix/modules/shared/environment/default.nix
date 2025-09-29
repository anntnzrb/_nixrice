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
