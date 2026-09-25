{ pkgs, ... }:
let

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
in
{
  home.packages = [ fastfetch ];

  xdg.configFile =
    let
      configFile = "config.jsonc";
    in
    {
      fastfetch = {
        enable = true;
        source = ./${configFile};
        target = "fastfetch/${configFile}";
        recursive = true;
      };
    };
}
