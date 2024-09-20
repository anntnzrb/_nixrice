{ config, lib, ... }:
let
  cfg = config.liberion.cli.direnv;
in
{
  options.liberion.cli.direnv = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
    };
  };
}
