{ lib, ... }:
let
  # For non-boolean options or precise defaults outside the enable-helper
  # naming convention.
  mkOpt =
    type: default: description:
    lib.mkOption { inherit type default description; };

  mkOpt' = type: def: mkOpt type def null;

  # Description-free default-enabled baseline (no generated option docs).
  mkOptEnabled' = mkOpt lib.types.bool true null;

  # Description-free opt-in feature (no generated option docs).
  mkOptDisabled' = mkOpt lib.types.bool false null;
in
{
  module = {
    inherit mkOpt' mkOptEnabled' mkOptDisabled';

    on.enable = true;
    off.enable = false;
  };
}
