{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib.${namespace}.launchd.darwin) mkGuiAppAgent;

  cfg = config.${namespace}.programs.aldente;
in
{
  options.${namespace}.programs.aldente = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable (
    {
      ${namespace}.homebrew.packages.casks = [ "aldente" ];

      system.defaults.CustomUserPreferences."com.apphousekitchen.aldente-pro" = {
        launchAtLogin = false;
      };
    }
    // mkGuiAppAgent {
      name = "aldente";
      app = "/Applications/AlDente.app";
      managedBy = "${namespace}.programs.aldente.enable";
    }
  );
}
