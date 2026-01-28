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
    user = on;

    wsl = on;

    network.ssh = on;
  };
}
