# Module factory for opt-in features whose only option is `enable`:
#
#   import ../../toggle.nix "cli.btop" ({ pkgs, ... }: { programs.btop.enable = true; })
#   import ../../toggle.nix "cli.husky" "husky"   # shorthand: install pkgs.husky
#
# declares `liberion.<path>.enable` and applies the body only when it is on.
# Works in NixOS, nix-darwin and Home Manager modules alike.
path: body:
{
  config,
  lib,
  pkgs,
  ...
}@args:
# `_module.args` (pkgs) reach a module only when named, so the factory names
# every one a body may take; specialArgs (inputs, self) always pass through
let
  enablePath = [ "liberion" ] ++ lib.splitString "." path ++ [ "enable" ];
in
{
  options = lib.setAttrByPath enablePath lib.liberion.module.mkOptDisabled';
  config = lib.mkIf (lib.getAttrFromPath enablePath config) (
    if builtins.isString body then
      { home.packages = [ pkgs.${body} ]; }
    else
      body args
  );
}
