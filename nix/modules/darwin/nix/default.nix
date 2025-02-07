{
  lib,
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.nix;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/nix/default.nix") ];

  config = {
    services.nix-daemon.enable = true;

    nix = {
      settings.trusted-users = [
        "root"
        "@admin"
      ];

      gc.interval = {
        Day = 7;
        Hour = 6;
      };
    };
  };
}
