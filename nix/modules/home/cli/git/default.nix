{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' getModuleFiles;

  cfg = config.${namespace}.cli.git;
in
{
  imports = getModuleFiles { path = ./.; };

  options.${namespace}.cli.git = {
    enable = mkOptDisabled';

    diff = {
      # TODO: check https://github.com/Wilfred/difftastic/issues/637
      difftastic.enable = mkOptDisabled';
    };

    lazygit.enable = mkOptDisabled';
    gh.enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.difftastic = cfg.diff.difftastic;

    programs.git = {
      inherit (cfg) enable;

      settings = {
        user = {
          name = "anntnzrb";
          email = "anntnzrb@proton.me";
        };

        core = {
          autocrlf = "input";
          eol = "lf";
        };
        init.defaultBranch = "main";
        fetch.prune = true;
        rebase.autoStash = true;
        pull.rebase = true;
        push = {
          autoSetupRemote = true;
          default = "current";
        };

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

  };
}
