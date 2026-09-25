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
