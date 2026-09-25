{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOpt' mkOptEnabled';

  inherit (lib.types)
    str
    nullOr
    listOf
    singleLineStr
    ;

  cfg = config.liberion.user;
in
{
  options.liberion.user = {
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
