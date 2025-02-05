{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt';

  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = {
    name = mkOpt' lib.types.str "annt";
  };

  config = {
    users.users.${cfg.name} = {
      inherit (cfg) name;
    };
  };
}
