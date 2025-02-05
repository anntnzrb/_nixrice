{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.desktop.bitwarden;
in
{
  options.${namespace}.desktop.bitwarden = {
    enable = mkOptBool';
    desktop.enable = mkOptBool';
    cli.enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (lib.optionals cfg.desktop.enable [
        pkgs.bitwarden-desktop
      ])
      ++ (lib.optionals cfg.cli.enable [
        pkgs.bitwarden-cli
      ]);
  };
}
