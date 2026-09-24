{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.espanso;
in
{
  config.services.espanso.matches.default.matches = lib.mkIf cfg.enable [
    {
      trigger = ">!mail";
      replace = "anntnzrb@proton.me";
    }
    {
      trigger = ">!mail";
      replace = "juangonz@espol.edu.ec";
    }
  ];
}
