{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.browsers.brave;
in
{
  options.liberion.desktop.browsers.brave = {
    commandLineArgs = mkOpt' (listOf str) [
      "--no-default-browser-check"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
    ];
    "brave-ai".enable = mkOpt' lib.types.bool false;
    news.enable = mkOpt' lib.types.bool false;
    rewards.enable = mkOpt' lib.types.bool false;
    vpn.enable = mkOpt' lib.types.bool false;
    wallet.enable = mkOpt' lib.types.bool false;
  };

  config = {
    programs.brave = {
      enable = true;
      inherit (cfg) commandLineArgs;
    };
  };
}
