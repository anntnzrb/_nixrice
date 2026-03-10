{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;

  cfg = config.${namespace}.programs.vscode;
in
{
  options.${namespace}.programs.vscode = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.casks = [ "visual-studio-code" ];
  };
}
