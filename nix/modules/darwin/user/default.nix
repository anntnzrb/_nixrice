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
    (lib.snowfall.fs.get-file "modules/shared/user/default.nix")
  ];

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      inherit (cfg) name;
    };
  };
}
