import ../../../toggle.nix "suites.desktop" (
  { lib, ... }:
  let
    inherit (lib.liberion.module) on;
  in
  {
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
  }
)
