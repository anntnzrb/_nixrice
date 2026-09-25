{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.suites.desktop;
in
{
  options.liberion.suites.desktop = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    # zsh as an interactive shell; this is a forced default
    # customization is done via hm
    programs.zsh = on;

    liberion = {
      system = {
        keyboard = on;
        dock = on;
        finder = on;
        trackpad = on;
      };

      programs = {
        bitwarden = on;
        orbstack = on;
        whatsapp = on;
      };
      network.ssh = on;

      homebrew = on;
    };
  };
}
