{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user =
    with lib.${namespace};
    with lib.types;
    {
      name = mkOpt' types.str "annt";
    };

  config = {
    users.users.${cfg.name} = {
      inherit (cfg) name;
    };
  };
}
