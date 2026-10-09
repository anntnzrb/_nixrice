{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) str ints;

  cfg = config.liberion.core;
in
{
  options.liberion.core.keyboard = {
    layout = mkOpt' str "us";
    variant = mkOpt' str "altgr-intl";
    autoRepeatDelay = mkOpt' ints.unsigned 220;
    autoRepeatInterval = mkOpt' ints.unsigned 50;
  };

  config = {
    home = {
      keyboard = { inherit (cfg.keyboard) layout variant; };
      stateVersion = lib.mkDefault "22.05";
    };

    targets.darwin = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      copyApps.enable = true;
      linkApps.enable = false;
    };

    # workaround for home-manager#7935
    manual = {
      manpages.enable = false;
      html.enable = false;
      json.enable = false;
    };

    systemd.user.startServices = "sd-switch";
    programs.home-manager.enable = true;
  };
}
