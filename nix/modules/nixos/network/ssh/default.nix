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
    (lib.snowfall.fs.get-file "modules/shared/network/ssh/default.nix")
  ];

  config = lib.mkIf cfg.enable { };
}
