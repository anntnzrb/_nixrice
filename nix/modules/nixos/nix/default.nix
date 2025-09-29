{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.nix;
in
{
  imports = [
    (lib.snowfall.fs.get-file "modules/shared/nix/default.nix")
  ];

  config = lib.mkIf cfg.enable {
    nix = {
      settings.trusted-users = [
        "root"
        "@wheel"
      ];

      gc = {
        dates = "weekly";
        randomizedDelaySec = "45min";
      };
    };

    documentation.man.generateCaches = true;
  };
}
