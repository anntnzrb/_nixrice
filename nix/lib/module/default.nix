{ lib, ... }:
rec {

  # Creates an option with the specified type, default value, and description.
  # Alias for mkOption.
  mkOpt =
    type: default: description:
    lib.mkOption { inherit type default description; };

  # Creates an option with the specified type and default value, no description.
  # Alias for mkOption.
  mkOpt' = type: def: mkOpt type def null;

  # Creates a boolean option defaulting to false, with given description.
  # Alias for mkEnableOption.
  mkOptBool = desc: lib.mkEnableOption desc;

  # Creates a boolean option defaulting to false, no description.
  # Alias for mkEnableOption.
  mkOptBool' = mkOptBool null;

  # Creates a boolean option defaulting to true, with given description.
  # Alias for mkOption.
  mkOptEnabled = desc: mkOpt lib.types.bool true desc;

  # Creates a boolean option defaulting to true, no description.
  # Alias for mkOption.
  mkOptEnabled' = mkOpt lib.types.bool true null;

  # Creates a boolean option defaulting to false, with given description.
  # Alias for mkOption.
  mkOptDisabled = desc: mkOpt lib.types.bool false desc;

  # Creates a boolean option defaulting to false, no description.
  # Alias for mkOption.
  mkOptDisabled' = mkOpt lib.types.bool false null;

  # Alias for enabling an option.
  on.enable = true;

  # Alias for disabling an option.
  off.enable = false;
}
