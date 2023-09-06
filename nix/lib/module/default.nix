{lib, ...}: let
  inherit (lib) types mkOption;
in rec {
  ## ```nix
  ## mkOpt nixpkgs.lib.types.str "My default" "Description of my option."
  ## ```
  mkOpt = type: default: description:
    mkOption {inherit type default description;};

  ## ```nix
  ## mkOpt' nixpkgs.lib.types.str "My default"
  ## ```
  mkOpt' = type: default: mkOpt type default null;

  ## ```nix
  ## mkOptBool true "Description of my option."
  ## ```
  mkOptBool = mkOpt types.bool;

  ## ```nix
  ## mkOptBool' true
  ## ```
  mkOptBool' = mkOpt' types.bool;

  on = {
    ## ```nix
    ## services.foo = enabled;
    ## ```
    enable = true;
  };

  off = {
    ## ```nix
    ## services.bar = disabled;
    ## ```
    enable = false;
  };

  ## ```nix
  ## mkAssertionModule config.xserver.enable "xserver.enable is required."
  ## ```
  mkAssertionModule = assertion: message: {
    inherit assertion message;
  };
}
