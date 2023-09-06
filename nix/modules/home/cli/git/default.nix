{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.liberion.cli.git;
in {
  config = {
    programs.git = {
      enable = true;
      userName = "anntnzrb";
      userEmail = "anntnzrb@protonmail.com";

      extraConfig = {
        init = {
          defaultBranch = "main";
        };
      };

      aliases = {
        br = "branch -ailv";
        ca = "commit --ammend";
        cm = "commit -m";
        co = "checkout";
        cob = "checkout -b";
        d = "diff";
        last = "log -1 HEAD";
        lg = "log --graph --decorate --stat";
        lga = "log --all --graph --decorate --stat";
        ls = "ls-files";
        ps = "push";
        st = "status -sb";
        unstage = "reset --hard HEAD";

        # function-aliases
        cp = "!f() { git commit -m \"`date '+%F :: %T (%Z)'`\" ; git push; }; f";
        ac = "!f() { git add -A ; git commit -am \"`date '+%F :: %T (%Z)'`\"; }; f";
        acp = "!f() { git add -A ; git commit -am \"`date '+%F :: %T (%Z)'`\" ; git push; }; f";
      };
    };
  };
}
