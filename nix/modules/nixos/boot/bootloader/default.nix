{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptEnabled';

  cfg = config.${namespace}.boot.bootloader;
in
{
  options.${namespace}.boot.bootloader = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      timeout = 10;
      efi.canTouchEfiVariables = true;
    };
  };
}
