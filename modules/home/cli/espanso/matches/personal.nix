{ lib, config, ... }:
let
  cfg = config.liberion.cli.espanso;
in
{
  config.services.espanso.matches.default.matches = lib.mkIf cfg.enable [
    {
      trigger = ">!mail";
      replace = lib.liberion.identity.git.email;
    }
    {
      trigger = ">!mail";
      replace = "juangonz@espol.edu.ec";
    }
  ];
}
