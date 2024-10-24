{
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
{
  config.programs.firefox.profiles.default.extensions =
    with inputs.firefox-addons.packages.${system};
    [
      # utils
      ublock-origin # ad-blocker
      clearurls
      istilldontcareaboutcookies
      sponsorblock

      # ui/ux
      refined-github
    ]
    ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
      bitwarden # pw manager
    ]);
}
