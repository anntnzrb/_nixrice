{ config
, lib
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
    programs.neovim = {
      enable = true;

      withNodeJs = false;
      withPython3 = false;
      withRuby = false;

      extraConfig = ''
        set clipboard=unnamedplus
      '';
    };
  };
}
