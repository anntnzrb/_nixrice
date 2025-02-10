{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.git;
in
{
  imports = [ ./lazygit.nix ];

  options.${namespace}.cli.git = {
    enable = mkOptDisabled';
    lazygit.enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      inherit (cfg) enable;
      difftastic.enable = true;

      userName = "anntnzrb";
      userEmail = "anntnzrb@proton.me";

      extraConfig = {
        init.defaultBranch = "main";
        fetch.prune = true;
        rebase.autoStash = true;
        pull.rebase = true;
        push = {
          autoSetupRemote = true;
          default = "current";
        };
      };

      aliases = {
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

        # function-aliases
        nuke = "!f() { git reset --hard && git clean -fdx }; f";

        qc = "!f() { git commit -m \"`date '+%F :: %T (%Z)'`\" }; f";

        srp = "!f() { git diff --quiet && git diff --cached --quiet || git stash push -m \"local\" && git rebase --merge && git stash pop; }; f";
      };
    };

    # FIXME: defaultSopsFile is not set
    #sops.secrets."git/github/token" = { };
    #home.sessionVariables."GITHUB_TOKEN" = ''
    #  $(cat ${config.sops.secrets."git/github/token".path})
    #'';
  };
}
