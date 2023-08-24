{ me
, pkgs
, config
, inputs
, ...
}:
let
  emacsDir = "${config.xdg.configHome}/emacs";
in
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29;
  };

  # add `doom` cmd to PATH
  home.sessionPath = [ "${emacsDir}/bin" ];

  home.packages = with pkgs;[
    emacs-all-the-icons-fonts
    emacsPackages.emojify-logos
  ];

  xdg.configFile = {
    "doom" = {
      enable = false;
      target = "doom";
      recursive = true;
      source = "${me.dotfilesDir}/doom";
    };
  };
}
