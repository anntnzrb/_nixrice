{
  lib,
  namespace,
  ...
}:
with lib.${namespace}.zed-editor;
{
  config.programs.zed-editor = {
    extensions = [ "nix" ];

    userSettings = {
      languages.Nix = {
        language_servers = [
          "nixd"
          "!nil"
        ];

        formatter = util.mkFmt "nixfmt" [ ];
      };

      lsp.nixd = {
        binary = util.useDirenv;
      };
    };
  };
}
