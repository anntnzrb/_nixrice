{ lib, ... }:
rec {

  # Alias for mkOption
  mkOpt =
    type: default: description:
    lib.mkOption { inherit type default description; };

  # Alias for mkOption with no description
  mkOpt' = type: def: mkOpt type def null;

  # Alias for mkEnableOption
  mkOptBool = desc: lib.mkEnableOption desc;

  # Alias for mkEnableOption with no description
  mkOptBool' = mkOptBool null;

  # Alias for mkEnableOption but defaulting to true
  mkOptEnabled = desc: mkOpt lib.types.bool true desc;

  # Alias for mkEnableOption but defaulting to true with no description
  mkOptEnabled' = mkOpt lib.types.bool true null;

  # Alias for enabling a service
  on = {
    enable = true;
  };

  # Alias for disabling a service
  off = {
    enable = false;
  };
}
