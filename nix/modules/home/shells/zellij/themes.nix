{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.shells.zellij;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."zellij/config.kdl".text = # kdl
      ''
        theme "catppuccin-frappe"
      '';
  };
}
