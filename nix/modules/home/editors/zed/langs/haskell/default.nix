{
  lib,
  namespace,
  ...
}:
with lib.${namespace}.zed-editor;
{
  config.programs.zed-editor.userSettings = {
    languages.Haskell = {
      formatter = util.mkFmt "fourmolu" [
        "--stdin-input-file"
        "{buffer_path}"
        "-"
      ];
    };

    lsp.haskell-language-server = {
      binary = util.useDirenv;
    };
  };
}
