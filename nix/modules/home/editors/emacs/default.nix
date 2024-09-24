{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.editors.emacs;

  packages = {
    dependencies = with pkgs; [
      fd
      (ripgrep.override { withPCRE2 = true; })

      # lookup
      sqlite
      wordnet
    ];

    emacsPkgs = with pkgs.emacsPackages; [ vterm ];

    dicts = with pkgs; [
      (aspellWithDicts (
        dicts: with dicts; [
          # english
          en
          en-computers
          en-science

          es # spanish/español
          de # german/deutsch
        ]
      ))
    ];
  };
in
{
  options.${namespace}.editors.emacs = with lib.${namespace}; {
    enable = mkOptBool';
    pgtk = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;

      package = pkgs.emacs29.override {
        withGTK3 = true;
        withGTK2 = false;
        withPgtk = cfg.pgtk && !pkgs.stdenv.isDarwin;
        withNativeCompilation = true; # emacs28+
        withTreeSitter = true; # emacs29+
        withSQLite3 = true;
      };
    };

    home.packages = with packages; emacsPkgs ++ dependencies ++ dicts;
  };
}
