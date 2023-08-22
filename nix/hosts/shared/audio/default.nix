{ pkgs, ... }: {
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      audio.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    pamixer
    pasystray
    pulsemixer
  ];
}
