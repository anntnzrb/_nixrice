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
  imports = [
    (lib.${namespace}.fs.getFile "modules/shared/user/default.nix")
  ];

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      inherit (cfg) name;
    };
  };
}
