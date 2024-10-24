{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.liberion.hardware.audio;
in
{
  options.liberion.hardware.audio = with lib.liberion; {
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
