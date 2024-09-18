{ config
, ...
}:
let
  _cfg = config.liberion.boot.bootloader;
in
{
  config = {
    boot.loader = {
      timeout = 10;
      efi.canTouchEfiVariables = true;
    };
  };
}
