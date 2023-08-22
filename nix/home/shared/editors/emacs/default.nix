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

  home.sessionPath = [ "${emacsDir}/bin" ];

  home.packages = with pkgs;[
    emacs-all-the-icons-fonts
    emacsPackages.emojify
  ];

  xdg.configFile = {
    "doom" = {
      enable = true;
      target = "doom";
      recursive = true;
      source = "${me.dotfilesDir}/doom";
    };
  };
}
