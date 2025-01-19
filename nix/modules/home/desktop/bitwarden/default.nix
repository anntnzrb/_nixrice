{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.bitwarden;
in
{
  options.${namespace}.desktop.bitwarden = with lib.${namespace}; {
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
