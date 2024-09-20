{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.home;
in
{
  options.liberion.home =
    with lib.liberion;
    with lib.types;
    {
      packages = mkOpt' (listOf package) [ ];

      keyboard = {
        layout = mkOpt' str "us";
        variant = mkOpt' str "altgr-intl";
        autoRepeatDelay = mkOpt' ints.unsigned 220;
        autoRepeatInterval = mkOpt' ints.unsigned 50;
      };
    };

  config = {
    home = {
      inherit (cfg) packages;
      keyboard = {
        inherit (cfg.keyboard) layout variant;
      };
      stateVersion = "22.05";

      # disable "Last Login..." preliminary message on OSX
      file.".hushlogin" = lib.mkIf pkgs.stdenv.isDarwin { text = ""; };
    };

    systemd.user.startServices = "sd-switch";
    programs.home-manager.enable = true;
  };
}
