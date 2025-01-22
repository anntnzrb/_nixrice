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
