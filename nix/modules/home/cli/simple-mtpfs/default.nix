{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.cli.simple-mtpfs;
in
{

  options.liberion.cli.simple-mtpfs = {
    enable = lib.mkEnableOption "simple-mtpfs";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.simple-mtpfs ];
  };
}
