{
  lib,
  config,
  inputs,
  namespace,
  system,
  ...
}:
let
  cfg = config.${namespace}.editors.neovim;
in
{
  options.${namespace}.editors.neovim = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ inputs.neovim-annt.packages.${system}.neovim ];
      shellAliases.v = "nvim";
    };
  };
}
