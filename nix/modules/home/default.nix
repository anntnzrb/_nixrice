{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptEnabled'
    ;
  inherit (lib.types)
    str
    ints
    ;

  cfg = config.${namespace}.home;
in
{
  options.${namespace}.home = {
    enable = mkOptEnabled';
    keyboard = {
      layout = mkOpt' str "us";
      variant = mkOpt' str "altgr-intl";
      autoRepeatDelay = mkOpt' ints.unsigned 220;
      autoRepeatInterval = mkOpt' ints.unsigned 50;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      keyboard = {
        inherit (cfg.keyboard) layout variant;
      };
      stateVersion = "22.05";
    };

    systemd.user.startServices = "sd-switch";
    programs.home-manager.enable = true;
  };
}
