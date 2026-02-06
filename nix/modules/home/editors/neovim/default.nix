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
in
{
  options.${namespace}.editors.neovim = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.nixvim
      ];
      shellAliases.v = "nvim";
    };
  };
}
