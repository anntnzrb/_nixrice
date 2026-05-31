{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    # zsh as an interactive shell; this is a forced default
    # customization is done via hm
    programs.zsh = on;

    ${namespace} = {
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

      desktop.window-managers.darwin.aerospace = on;
      network.ssh = on;

      homebrew = on;
    };
  };
}
