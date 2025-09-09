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

  cfg = config.${namespace}.cli.qwen;
in
{
  options.${namespace}.cli.qwen = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.qwen = "bunx --bun @qwen-code/qwen-code@latest -- --yolo";
  };
}
