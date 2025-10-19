{
  lib,
  config,
  namespace,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.${namespace}.desktop.browsers.firefox;
in
{
  config = lib.mkIf cfg.enable {
    programs.firefox.profiles.default.extensions.packages =
      with inputs.firefox-addons.packages.${pkgs.system}; [
        # utils
        ublock-origin # ad-blocker
        #clearurls # broken
        istilldontcareaboutcookies
        sponsorblock

        # ui/ux
        refined-github
      ];
  };
}
