{ inputs, pkgs, ... }: {
  imports = [ inputs.self.homeModules.amp ];

  # Amp gives Linux a private headless desktop.
  liberion.ai.amp.extraArgs = [ "--desktop" ];

  home.packages = with pkgs; [
    ffmpeg
    labwc
    wlr-randr
  ];
}
