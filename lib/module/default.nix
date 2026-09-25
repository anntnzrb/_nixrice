{ lib, ... }:
let
  mkOpt' =
    type: default:
    lib.mkOption {
      inherit type default;
      description = null;
    };
in
{
  module = {
    inherit mkOpt';

    # Description-free default-enabled baseline (no generated option docs).
    mkOptEnabled' = mkOpt' lib.types.bool true;

    # Description-free opt-in feature (no generated option docs).
    mkOptDisabled' = mkOpt' lib.types.bool false;

    on.enable = true;
    off.enable = false;
  };
}
