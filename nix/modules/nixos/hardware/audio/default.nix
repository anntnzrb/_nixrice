{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.hardware.audio;
in
{
  options.${namespace}.hardware.audio = with lib.${namespace}; {
    pipewire = {
      enable = mkOptBool';
    };
  };

  config = lib.mkIf cfg.pipewire.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;

      alsa.enable = true;
      audio.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    environment.systemPackages = with pkgs; [
      pamixer
      pulsemixer
      pasystray
    ];
  };
}
