{ config
, lib
, ...
}:
let
  cfg = config.liberion.cli.direnv;
in
{
  options.liberion.cli.direnv = {
    enable = lib.mkEnableOption "direnv";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
