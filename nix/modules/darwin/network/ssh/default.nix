{
  lib,
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.network.ssh;
in
{
  imports = [
    (lib.snowfall.fs.get-file "modules/shared/network/ssh/default.nix")
  ];

  config = {
    services.openssh.enable = true;
  };
}
