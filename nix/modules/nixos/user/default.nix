{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace})
    mkOpt'
    mkOptEnabled'
    ;

  inherit (lib.types)
    str
    nullOr
    listOf
    singleLineStr
    ;

  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = {
    name = mkOpt' str "annt";
    isNormalUser = mkOptEnabled';
    initialPassword = mkOpt' (nullOr str) "pass";
    extraGroups = mkOpt' (listOf str) [ ];

    authorizedKeys = mkOpt' (listOf singleLineStr) [ ];
  };

  config = {
    users.users.${cfg.name} = {
      inherit (cfg)
        name
        isNormalUser
        initialPassword
        extraGroups
        ;
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };
  };
}
