{
  programs.zathura = {
    enable = true;

    options = {
      sandbox = "none";
      selection-clipboard = "clipboard";
    };

    mappings = {
      "J" = "zoom out";
      "K" = "zoom in";

      "D" = "toggle_page_mode";
      "d" = "scroll half-down";
      "u" = "scroll half-up";

      "i" = "recolor";
      "r" = "reload";
      "p" = "print";
      "R" = "rotate";
    };
  };
}
