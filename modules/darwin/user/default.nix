{ lib, config, ... }:
let
  cfg = config.liberion.user;
in
{
  imports = [ (lib.liberion.fs.getFile "modules/shared/user/default.nix") ];

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = { inherit (cfg) name; };
  };
}
