{
  imports = [ ./theme.nix ];

  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";

    settings = {
      mgr = {
        ratio = [
          1 # left
          3 # middle
          3 # right
        ];
        sort_by = "natural";
        sort_sensitive = true;
        sort_dir_first = true;
        linemode = "size";
        show_hidden = true;
        show_symlink = true;
        title_format = "yazi @ {cwd}";
        mouse_events = [
          "click"
          "scroll"
          "touch"
          "move"
          "drag"
        ];
      };

      preview = {
        wrap = "no";
        tab_size = 2;
        max_width = 800;
        max_height = 1200;
        image_filter = "lanczos3";
        image_quality = 80;
      };
    };
  };
}
