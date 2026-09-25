{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.editors.neovim;

  package = inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.nixvim;
in
{
  options.liberion.editors.neovim = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ package ];
      shellAliases.v = lib.getExe package;
    };
  };
}
