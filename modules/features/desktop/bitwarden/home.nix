{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.desktop.bitwarden;
in
{
  options.liberion.desktop.bitwarden = {
    desktop.enable = mkOptDisabled';
    cli.enable = mkOptDisabled';
  };

  config = {
    home.packages =
      (lib.optionals cfg.desktop.enable [ pkgs.bitwarden-desktop ])
      ++ (lib.optionals cfg.cli.enable [ pkgs.bitwarden-cli ]);
  };
}
