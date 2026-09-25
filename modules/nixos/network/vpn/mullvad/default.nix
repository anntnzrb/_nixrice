import ../../../../toggle.nix "network.vpn.mullvad" (
  { pkgs, ... }: {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
      enableExcludeWrapper = false;
    };
  }
)
