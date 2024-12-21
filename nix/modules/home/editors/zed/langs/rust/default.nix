{
  lib,
  namespace,
  ...
}:
with lib.${namespace}.zed-editor;
{
  config.programs.zed-editor.userSettings = {
    languages.Rust = { };

    lsp.rust-analyzer = {
      binary = util.useDirenv;
    };
  };
}
