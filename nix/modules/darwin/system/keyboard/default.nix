{ config
, namespace
, ...
}:
let
  _cfg = config.${namespace}.darwin.system.keyboard;
in
{
  config = {
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };
}
