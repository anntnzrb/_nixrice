{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.editors.neovim;

  package = inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.nixvim;
in
{
  options.${namespace}.editors.neovim = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        package
      ];
      shellAliases.v = lib.getExe package;
    };
  };
}
