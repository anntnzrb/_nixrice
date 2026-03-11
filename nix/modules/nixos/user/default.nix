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

  inherit (lib.types)
    str
    nullOr
    listOf
    singleLineStr
    ;

  cfg = config.${namespace}.user;
in
{
  imports = [
    (lib.${namespace}.fs.getFile "modules/shared/user/default.nix")
  ];

  options.${namespace}.user = {
    isNormalUser = mkOptEnabled';
    initialPassword = mkOpt' (nullOr str) "pass";
    extraGroups = mkOpt' (listOf str) [ ];

    authorizedKeys = mkOpt' (listOf singleLineStr) [ ];
  };

  config = lib.mkIf cfg.enable {
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
