{ inputs, system, ... }:
with inputs.firefox-addons.packages.${system};
[
  # utils
  bitwarden # pw manager
  ublock-origin # ad-blocker
  clearurls
  istilldontcareaboutcookies

  # ui/ux
  refined-github
]
