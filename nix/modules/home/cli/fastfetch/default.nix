{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  fastfetch =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.fastfetch.overrideAttrs (old: {
        # makeLibraryPath adds this nonexistent directory and retains the entire SDK.
        postInstall =
          builtins.replaceStrings [ ":${pkgs.apple-sdk_15}/lib" ] [ "" ]
            old.postInstall;
      })
    else
      pkgs.fastfetch;

  cfg = config.${namespace}.cli.fastfetch;
in
{
  options.${namespace}.cli.fastfetch = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ fastfetch ];

    xdg.configFile =
      let
        configFile = "config.jsonc";
      in
      {
        fastfetch = on // {
          source = ./${configFile};
          target = "fastfetch/${configFile}";
          recursive = true;
        };
      };
  };
}
