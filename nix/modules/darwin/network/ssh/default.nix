{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.network.ssh;
in
{
  imports = [
    (lib.${namespace}.fs.getFile "modules/shared/network/ssh/default.nix")
  ];

  config = lib.mkIf cfg.enable {
    services.openssh = {
      inherit (cfg) enable;
    };
  };
}
