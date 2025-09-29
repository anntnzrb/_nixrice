{
  lib,
  inputs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.wsl;
in
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  options.${namespace}.wsl = {
    enable = mkOptDisabled';
  };

  config = {
    wsl = lib.mkIf cfg.enable {
      inherit (cfg) enable;
      defaultUser = config.${namespace}.user.name;
      docker-desktop = on;
    };

    programs.nix-ld = on;
  };
}
