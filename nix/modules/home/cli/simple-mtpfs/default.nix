{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.cli.simple-mtpfs;
in
{

  options.liberion.cli.simple-mtpfs = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.simple-mtpfs ];
  };
}
