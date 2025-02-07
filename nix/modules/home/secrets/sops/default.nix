{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptBool'
    ;

  inherit (lib.types) path;

  cfg = config.${namespace}.secrets.sops;
in
{
  options.${namespace}.secrets.sops = {
    enable = mkOptBool';
    defaultSopsFile = mkOpt' path (lib.snowfall.fs.get-file "secrets/default.yml");
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
      ssh-to-age
    ];

    sops = {
      inherit (cfg) defaultSopsFile;
      defaultSopsFormat = "yaml";

      age = {
        generateKey = true;
        keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      };
    };
  };
}
