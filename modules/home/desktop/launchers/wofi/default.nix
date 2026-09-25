import ../../../../toggle.nix "desktop.launchers.wofi" (_: {
  programs.wofi = {
    enable = true;

    settings = {
      location = "bottom-right";
    };
  };
})
