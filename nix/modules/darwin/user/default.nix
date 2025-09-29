{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptEnabled'
    ;

  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = {
    enable = mkOptEnabled';
    name = mkOpt' lib.types.str "annt";
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      inherit (cfg) name;
    };
  };
}
