# oulu's own home, ported verbatim from the clan-test flat modules; it does not
# use the liberion home modules.
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  nixvim =
    inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.nixvim
      or pkgs.neovim;
in
{
  home = {
    stateVersion = "26.05";
    sessionPath = [ "$HOME/.local/bin" ];
    packages = [
      pkgs.bun
      pkgs.nodejs
      pkgs.uv
      nixvim
    ];
    shellAliases.v = lib.getExe nixvim;
  };

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting ""
        bind \cf forward-char
      '';
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "anntnzrb";
          email = "anntnzrb@proton.me";
        };
        init.defaultBranch = "main";
        # common ancestor in conflicts, common prefixes/suffixes stripped
        merge.conflictStyle = "zdiff3";
        commit.verbose = true;
        branch.sort = "-committerdate";
        tag.sort = "version:refname";
        column.ui = "auto";
        help.autocorrect = "prompt";
        push.autoSetupRemote = true;
        pull.rebase = false;
        checkout.workers = 0;
        feature.manyFiles = true;
        maintenance.auto = true;
      };
    };

    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };

    lazygit = {
      enable = true;
      settings.gui.theme = {
        activeBorderColor = [
          "#a6e3a1"
          "bold"
        ];
        inactiveBorderColor = [ "#a6adc8" ];
      };
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config.global = {
        load_dotenv = true;
        strict_env = true;
        hide_env_diff = true;
      };
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    btop = {
      enable = true;
      settings = {
        color_theme = "Default";
        theme_background = false;
        truecolor = true;
        force_tty = false;
        presets = "cpu:0:default,mem:0:default,proc:0:default";
        graph_symbol = "braille";
        shown_boxes = "proc cpu mem net";
        update_ms = 1500;
        proc_sorting = "cpu lazy";
        proc_tree = true;
        check_temp = true;
        cpu_sensor = "Auto";
      };
    };

    starship = {
      enable = true;
      settings = {
        add_newline = false;
        command_timeout = 500;
        scan_timeout = 10;
        follow_symlinks = false;

        format = "$username@$hostname $os $directory$git_branch$git_status$nix_shell$direnv\n$time $shell$cmd_duration $character";

        character = {
          success_symbol = "[λ](bold green)";
          error_symbol = "[λ](bold red)";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
          style = "bold cyan";
        };

        cmd_duration = {
          min_time = 2000;
          style = "bold yellow";
        };

        git_branch = {
          style = "bold purple";
          symbol = " ";
        };

        git_status.style = "bold red";

        nix_shell = {
          symbol = " ";
          format = "via [$symbol$state]($style) ";
        };

        direnv = {
          disabled = false;
          symbol = " ";
        };

        hostname = {
          ssh_only = false;
          format = "[$hostname]($style)";
          style = "bold green";
        };

        username = {
          show_always = true;
          format = "[$user]($style)";
          style_user = "bold yellow";
          style_root = "bold red";
        };

        time = {
          disabled = false;
          format = "[$time]($style)";
          style = "dimmed white";
        };

        # cloud context modules add prompt latency
        aws.disabled = true;
        gcloud.disabled = true;
        azure.disabled = true;
      };
    };
  };
}
