{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.bitwarden;
in
{
  options.${namespace}.desktop.bitwarden = {
    enable = mkOptDisabled';
    desktop.enable = mkOptDisabled';
    cli.enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (lib.optionals cfg.desktop.enable [ pkgs.bitwarden-desktop ])
      ++ (lib.optionals cfg.cli.enable [ pkgs.bitwarden-cli ]);
  };
}
