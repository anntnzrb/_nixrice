{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.liberion.fs) getModuleFiles;
  inherit (lib) range;
  inherit (lib.types) int listOf;

  cfg = config.liberion.desktop.window-managers.darwin.aerospace;
  yashikiCfg = config.liberion.desktop.window-managers.darwin.yashiki;
  yashikiPkg = pkgs.yashiki;
  aerospaceLib = import ./lib.nix { inherit lib; };
in
{
  imports = getModuleFiles {
    path = ./.;
    ignore = [
      "lib.nix"
      "rules.nix"
    ];
  };

  options.liberion.desktop.window-managers.darwin.aerospace = {
    enable = mkOptDisabled';
    modifier = mkOpt' lib.types.str "alt";
    workspaceRange = mkOpt' (listOf int) (range 0 9);
  };

  config = lib.mkMerge [
    { _module.args.aerospaceLib = aerospaceLib; }
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !yashikiCfg.enable;
          message = "liberion.desktop.window-managers.darwin.aerospace cannot be enabled together with liberion.desktop.window-managers.darwin.yashiki.";
        }
      ];

      services.aerospace = {
        enable = true;
        package = pkgs.aerospace;
        settings = {
          start-at-login = false;
          after-login-command = [ ];
          on-window-detected = aerospaceLib.mkRules (import ./rules.nix aerospaceLib);
        };
      };

      launchd.user.agents.aerospace.serviceConfig = {
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
      };

      system.activationScripts.postActivation.text = lib.mkAfter ''
        if [ -n "''${SUDO_USER:-}" ]; then
          user="''${SUDO_USER}"
        else
          user="${config.system.primaryUser}"
        fi

        uid="$(id -u "$user" 2>/dev/null || true)"
        if [ -n "$uid" ]; then
          launchctl bootout "gui/$uid/org.nixos.yashiki" >/dev/null 2>&1 || :
        fi

        ${yashikiPkg}/bin/yashiki stop >/dev/null 2>&1 || :
      '';

      # goodies
      # cf. https://nikitabobko.github.io/AeroSpace/goodies
      system.defaults.NSGlobalDomain = {
        NSWindowShouldDragOnGesture = true;
        NSAutomaticWindowAnimationsEnabled = true;
      };
    })
  ];
}
