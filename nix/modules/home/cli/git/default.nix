{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.git;
in
{

  options.${namespace}.cli.git = with lib.${namespace}; {
    enable = mkOptBool';

    lazygit = {
      enable = mkOptBool';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "anntnzrb";
      userEmail = "anntnzrb@proton.me";

      extraConfig = {
        init = {
          defaultBranch = "main";
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

    programs.lazygit = lib.mkIf cfg.lazygit.enable { enable = true; };

    home.shellAliases = lib.mkIf cfg.lazygit.enable { gg = "lazygit"; };
  };
}
