{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptEnabled';

  cfg = config.liberion.boot.bootloader;
in
{
  options.liberion.boot.bootloader = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      timeout = 10;
      efi.canTouchEfiVariables = true;
    };
  };
}
