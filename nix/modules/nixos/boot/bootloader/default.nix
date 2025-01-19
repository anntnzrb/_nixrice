{
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.boot.bootloader;
in
{
  config = {
    boot.loader = {
      timeout = 10;
      efi.canTouchEfiVariables = true;
    };
  };
}
