{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.git;
in
{
  options.liberion.cli.git = {
    enable = mkOptDisabled';

    diff = {
      # TODO: check https://github.com/Wilfred/difftastic/issues/637
      difftastic.enable = mkOptDisabled';
    };

    lazygit.enable = mkOptDisabled';
    gh.enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs = {
      difftastic = cfg.diff.difftastic;

      git = {
        enable = true;

        settings = {
          user = {
            name = "anntnzrb";
            email = "anntnzrb@proton.me";
          };

          core = {
            autocrlf = "input";
            eol = "lf";
            preloadIndex = true;
            untrackedCache = true;
          };

          feature.manyFiles = true;
          checkout.workers = 0;

          init.defaultBranch = "main";

          fetch = {
            prune = true;
            pruneTags = true;
            parallel = 0;
            writeCommitGraph = true;
          };

          pull.rebase = false;

          push = {
            autoSetupRemote = true;
            default = "current";
            followTags = true;
            useForceIfIncludes = true;
          };

          rebase = {
            autoSquash = true;
            autoStash = true;
            updateRefs = true;
          };

          merge.conflictStyle = "zdiff3";

          diff = {
            algorithm = "histogram";
            colorMoved = "default";
            colorMovedWS = "allow-indentation-change";
            mnemonicPrefix = true;
            renames = true;
          };

          rerere = {
            enabled = true;
            autoupdate = true;
          };

          commit.verbose = true;
          branch.sort = "-committerdate";
          tag.sort = "version:refname";
          column.ui = "auto";
          help.autocorrect = "prompt";

          maintenance.auto = true;

          alias = {
            br = "branch -ailv";
            ca = "commit --amend";
            cm = "commit -m";
            co = "checkout";
            cob = "checkout -b";
            d = "diff";
            lg = "log --all --graph --decorate --stat";
            ls = "ls-files";
            ps = "push";
            st = "status -sb";

            nuke = "!git reset --hard && git clean -fdx";
            qc = "!git commit -m \"$(date '+%F :: %T (%Z)')\"";
            srp = "!git diff --quiet && git diff --cached --quiet || git stash push -m 'local' && git rebase --merge && git stash pop";
          };
        };
      };

      gh = lib.mkIf cfg.gh.enable { enable = true; };

      lazygit = lib.mkIf cfg.lazygit.enable {
        enable = true;
        settings =
          lib.recursiveUpdate
            {
              disableStartupPopups = true;
              gui = {
                mouseEvents = true;
                showCommandLog = false;
              };
              spinner.rate = 100;
              git = {
                autoFetch = false;
                autoRefresh = true;
                fetchAll = false;
              };
              refresher = {
                refreshInterval = 3;
                fetchInterval = 180;
              };
            }
            (
              lib.optionalAttrs cfg.diff.difftastic.enable {
                git.paging.externalDiffCommand = "difft --color=always --display=inline --background dark";
              }
            );
      };
    };

    home.shellAliases = lib.mkIf cfg.lazygit.enable {
      gg = lib.getExe config.programs.lazygit.package;
    };
  };
}
