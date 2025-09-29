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
    wsl = on;

    network.ssh = on;
  };
}
