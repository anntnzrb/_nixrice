{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.home;
in
{
  options.${namespace}.home =
    with lib.${namespace};
    with lib.types;
    {
      keyboard = {
        layout = mkOpt' str "us";
        variant = mkOpt' str "altgr-intl";
        autoRepeatDelay = mkOpt' ints.unsigned 220;
        autoRepeatInterval = mkOpt' ints.unsigned 50;
      };
    };

  config = {
    home = {
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
