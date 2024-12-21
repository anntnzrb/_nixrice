{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.editors.zed;
  mod = "programs/zed-editor.nix";

  # list of language modules
  langs = [
    "nix"
    "rust"
    "haskell"
  ];
in
with lib.${namespace}.zed-editor;
{
  disabledModules = [ mod ];

  imports = [
    (import (inputs.home-manager-unstable + "/modules/${mod}"))
  ] ++ util.mapImports (map (lang: ./langs/${lang}/default.nix) langs);

  options.${namespace}.editors.zed = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config.programs.zed-editor = lib.mkIf cfg.enable {
    enable = true;
    extraPackages = with pkgs; [
      nixd
      nixfmt-rfc-style
    ];

    # a few defaults
    extensions = [
      "just"
      "toml"
    ];

    userSettings = {
      # -----------------------------------------------------------------------
      # general
      # -----------------------------------------------------------------------
      auto_update = false;
      restore_on_startup = "none";
      load_direnv = "shell_hook";

      # -----------------------------------------------------------------------
      # font
      # -----------------------------------------------------------------------
      ui_font_family = "Inconsolata Nerd Font Mono";
      ui_font_size = 16;
      buffer_font_family = "FantasqueSansM Nerd Font Mono";
      buffer_font_size = 16;

      # -----------------------------------------------------------------------
      # editing
      # -----------------------------------------------------------------------
      # behavior
      base_keymap = "VSCode";
      vim_mode = true;
      cursor_blink = false;
      format_on_save = "off";
      relative_line_numbers = true;

      # indentation and spacing
      tab_size = 4;
      indent_guides = {
        enabled = true;
        line_width = 6;
        active_line_width = 2;
        coloring = "indent_aware";
        background_coloring = "disabled";
      };

      # text wrapping and guides
      soft_wrap = "editor_width";
      show_wrap_guides = true;
      wrap_guides = [ 80 ];
      show_whitespaces = "boundary";

      # completion
      show_completions_on_input = false;
      show_inline_completions = false;

      # -----------------------------------------------------------------------
      # ui
      # -----------------------------------------------------------------------
      scrollbar.show = "never";
      file_finder.file_icons = true;
      tab_bar = {
        show = true;
        show_nav_history_buttons = false;
      };

      tabs = {
        file_icons = true;
        git_status = true;
      };

      # -----------------------------------------------------------------------
      # panels
      # -----------------------------------------------------------------------
      project_panel = {
        button = false;
        dock = "right";
        git_status = true;
        indent_size = 14;
        indent_guides.show = "always";
      };

      outline_panel = {
        button = true;
        default_width = 240;
        dock = "right";
        file_icons = true;
        folder_icons = true;
        git_status = true;
        indent_size = 20;
        auto_reveal_entries = true;
        auto_fold_dirs = true;
        indent_guides.show = "always";
      };

      # -----------------------------------------------------------------------
      # terminal
      # -----------------------------------------------------------------------
      terminal = {
        blinking = "off";
        copy_on_select = false;
        dock = "bottom";
        font_size = 12;
        line_height = "comfortable";
        button = false;
        detect_venv = "off";
      };

      # -----------------------------------------------------------------------
      # searching
      # -----------------------------------------------------------------------
      search = {
        case_sensitive = false;
        regex = true;
      };

      # -----------------------------------------------------------------------
      # AI
      # -----------------------------------------------------------------------
      assistant = {
        enabled = true;
        button = false;
        dock = "right";
        default_width = 540;
        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-latest";
        };
        version = "2";
      };

      features.inline_completion_provider = "supermaven";
    };
  };
}
