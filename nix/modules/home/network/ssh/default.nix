{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib) mkIf;
  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux;

  cfg = config.${namespace}.network.ssh;
in
{
  options.${namespace}.network.ssh = {
    enable = mkOptDisabled';
  };

  config = {
    programs.ssh = mkIf cfg.enable {
      inherit (cfg) enable;
      addKeysToAgent = "confirm 1h";
    };

    services.ssh-agent = mkIf (cfg.enable && isLinux) {
      inherit (cfg) enable;
    };
  };
}
