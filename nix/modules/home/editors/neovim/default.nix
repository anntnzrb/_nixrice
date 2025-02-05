{
  lib,
  config,
  inputs,
  namespace,
  system,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.editors.neovim;
in
{
  options.${namespace}.editors.neovim = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ inputs.neovim-annt.packages.${system}.neovim ];
      shellAliases.v = "nvim";
    };
  };
}
