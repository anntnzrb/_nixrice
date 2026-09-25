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
  name = lib.liberion.identity.user;
in
{
  options.liberion.user = {
    isNormalUser = mkOptEnabled';
    initialPassword = mkOpt' (nullOr str) "pass";
    extraGroups = mkOpt' (listOf str) [ ];

    authorizedKeys = mkOpt' (listOf singleLineStr) [ ];
  };

  config.users.users.${name} = {
    inherit name;
    inherit (cfg) isNormalUser initialPassword extraGroups;

    openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}
