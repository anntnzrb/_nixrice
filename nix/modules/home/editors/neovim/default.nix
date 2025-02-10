{
  lib,
  config,
  inputs,
  namespace,
  system,
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
      packages = [ inputs.neovim-annt.packages.${system}.nvf ];
      shellAliases.v = "nvim";
    };
  };
}
