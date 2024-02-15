{ config
, inputs
, lib
, system
, ...
}:
let
  cfg = config.liberion.editors.neovim;
in
{
  options.liberion.editors.neovim = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ inputs.neovim-annt.packages.${system}.neovim ];
  };
}
