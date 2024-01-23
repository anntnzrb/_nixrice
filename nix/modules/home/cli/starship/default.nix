{ config
, lib
, ...
}:
let
  cfg = config.liberion.cli.starship;
in
{
  options.liberion.cli.starship = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;

      settings = {
        add_newline = false;

        format = ''
          $username@$hostname $os $directory$all$time $shell$cmd_duration $character
        '';

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
