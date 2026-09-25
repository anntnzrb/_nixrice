{
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.wsl;
in
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  options.liberion.wsl = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    wsl = {
      inherit (cfg) enable;
      defaultUser = config.liberion.user.name;
      docker-desktop = on;
    };

    programs.nix-ld = on;
  };
}
