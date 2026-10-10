{ lib, root }:
let
  identity = import (root + "/identity.nix");

  mkOpt' =
    type: default:
    lib.mkOption {
      inherit type default;
      description = null;
    };

  mkReq' = type: lib.mkOption { inherit type; };

  routeHome = imports: {
    home-manager.users.${identity.user} = { inherit imports; };
  };

  inherit (import ./discovery.nix { inherit lib routeHome; }) load;

  fleet = load {
    base = root + "/modules/base";
    features = root + "/modules/features";
    profiles = root + "/modules/profiles";
  };
in
import ./services.nix { inherit lib root; }
// import ./fleet.nix { inherit identity lib root; }
// {
  inherit identity load routeHome;
  inherit (fleet) modules machineModule;

  module = {
    inherit mkOpt' mkReq';
    mkOptEnabled' = mkOpt' lib.types.bool true;
    mkOptDisabled' = mkOpt' lib.types.bool false;
  };

  darwin = import ./darwin.nix { inherit lib; };

  xorg.mkAutostartScript = xs: lib.concatStringsSep "\n" (map (x: x + " &") xs);
}
