{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.shells.starship;

  # avoid `$all`
  promptModules = [
    "$git_branch"
    "$git_status"
    "$nix_shell"
    "$direnv"
  ];
in
{
  options.${namespace}.shells.starship = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      inherit (cfg) enable;

      settings = {
        add_newline = false;
        command_timeout = 500;
        scan_timeout = 10;
        follow_symlinks = false;

        format = "$username@$hostname $os $directory${lib.concatStrings promptModules}\n$time $shell$cmd_duration $character";

        character = {
          success_symbol = "[➜ ](bold green)";
          error_symbol = "[✕ ](bold red)";
          vimcmd_symbol = "[➜ ](bold green)";
        };

        directory = {
          disabled = false;
          truncation_length = 8;
          truncation_symbol = "…/";
          truncate_to_repo = false;
        };

        cmd_duration = {
          disabled = false;
          min_time = 2000;
          format = " [took $duration](bold red)";
        };

        git_branch = {
          ignore_branches = [ ];
        };

        git_status = {
          ignore_submodules = true;
          format = "([$all_status]($style) )";
        };

        git_commit = {
          disabled = true;
        };

        git_metrics = {
          disabled = true;
        };

        git_state = {
          disabled = true;
        };

        hostname = {
          ssh_only = false;
          format = "[$ssh_symbol](bold blue)[$hostname](bold red)";
          disabled = false;
        };

        os = {
          disabled = false;
        };

        os.symbols = {
          Arch = "🐧";
          Artix = "🐧";
        };

        shell = {
          disabled = false;
          bash_indicator = "bash";
          fish_indicator = "fish";
          format = "[\\($indicator\\)](bold blue)";
        };

        time = {
          disabled = false;
          time_format = "%R";
          format = "🕙 [$time]($style)";
        };

        username = {
          disabled = false;
          show_always = true;
          format = "[$user]($style)";
        };

        aws.disabled = true;
        azure.disabled = true;
        gcloud.disabled = true;
        singularity.disabled = true;
      };
    };
  };
}
