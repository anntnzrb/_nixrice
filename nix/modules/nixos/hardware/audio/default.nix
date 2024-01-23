{ lib
, config
, pkgs
, ...
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

  config = {
    services.pipewire = lib.mkIf cfg.pipewire.enable {
      enable = true;

      alsa.enable = true;
      audio.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    environment.systemPackages = with pkgs; lib.mkIf cfg.pipewire.enable [
      pamixer
      pulsemixer
      pasystray
    ];
  };
}
