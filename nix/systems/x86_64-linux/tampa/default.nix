{
  lib,
  namespace,
  ...
}:

let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    wsl.enable = true;

    network.ssh = on;
  };
}
