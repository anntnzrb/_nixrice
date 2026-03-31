{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';
  inherit (lib.types) listOf str;

  cfg = config.${namespace}.desktop.browsers.brave;
in
{
  options.${namespace}.desktop.browsers.brave = {
    enable = mkOptDisabled';
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

  config = lib.mkIf cfg.enable {
    programs.brave = {
      inherit (cfg)
        enable
        commandLineArgs
        ;
    };
  };
}
