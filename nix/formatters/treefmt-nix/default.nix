{
  projectRootFile = ".git/config";
  programs = {
    nixfmt.enable = true;
    actionlint.enable = true;
    just.enable = true;

    deadnix = {
      enable = true;
      no-underscore = true;
    };

    statix = {
      enable = true;
      disabled-lints = [ "repeated_keys" ];
    };

    prettier = {
      enable = true;
      includes = [
        "*.css"
        "*.json{,c,5}"
        "*.md{,x}"
        "*.ya?ml"
      ];
    };
  };
}
