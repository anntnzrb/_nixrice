{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.editors.zed;
  mod = "programs/zed-editor.nix";
in
{
  disabledModules = [ mod ];
  imports = [ (import (inputs.home-manager-unstable + "/modules/${mod}")) ];

  options.${namespace}.editors.zed = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config.programs.zed-editor = lib.mkIf cfg.enable {
    enable = true;
    extraPackages = with pkgs; [
      nixd
      nixfmt-rfc-style
    ];
  };
}
