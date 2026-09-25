# Module factory for package-only enable toggles. Callers keep their own
# `default.nix`, so discovery position and `home.packages` merge order are
# unchanged; each passes its `${namespace}` option path and the `pkgs`
# attribute name to install when enabled.
path: package:
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  enablePath = [ namespace ] ++ lib.splitString "." path ++ [ "enable" ];
in
{
  options = lib.setAttrByPath enablePath mkOptDisabled';
  config = lib.mkIf (lib.getAttrFromPath enablePath config) {
    home.packages = [ pkgs.${package} ];
  };
}
