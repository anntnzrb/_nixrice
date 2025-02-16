{
  pkgs,
  inputs,
  ...
}:
{
  config.programs.firefox.profiles.default.extensions =
    with inputs.firefox-addons.packages.${pkgs.system}; [
      # utils
      ublock-origin # ad-blocker
      #clearurls # broken
      istilldontcareaboutcookies
      sponsorblock

      # ui/ux
      refined-github
    ];
}
