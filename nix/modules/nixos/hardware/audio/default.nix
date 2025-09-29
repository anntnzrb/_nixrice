{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    on
    ;

  cfg = config.${namespace}.hardware.audio;
in
{
  options.${namespace}.hardware.audio = {
    pipewire.enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.pipewire.enable {
    security.rtkit = on;

    services.pipewire = on // {
      alsa = on;
      audio = on;
      pulse = on;
      wireplumber = on;
    };

    environment.systemPackages = with pkgs; [
      pamixer
      pulsemixer
      pasystray
    ];
  };
}
