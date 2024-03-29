{ config
, lib
, ...
}:
let
  cfg = config.liberion.cli.git;
in
{

  options.liberion.cli.git = with lib.liberion; {
    enable = mkOptBool';
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
        wipe = "!f() { git reset --hard && git clean -fdx }; f";

        cp = "!f() { git commit -m \"`date '+%F :: %T (%Z)'`\" ; git push; }; f";
        ac = "!f() { git add -A ; git commit -am \"`date '+%F :: %T (%Z)'`\"; }; f";
        acp = "!f() { git add -A ; git commit -am \"`date '+%F :: %T (%Z)'`\" ; git push; }; f";
      };
    };
  };
}
