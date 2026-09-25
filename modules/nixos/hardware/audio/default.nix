{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.hardware.audio;
in
{
  options.liberion.hardware.audio = {
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
