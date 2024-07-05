{ config
, namespace
, ...
}:
let
  _cfg = config.${namespace}.system.keyboard;
in
{
  config = {
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };
}
