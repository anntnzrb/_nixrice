{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites.dev;
in
{
  options.${namespace}.suites.dev = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.cli = {
      omnix = on;
      husky = on;
      repomix = on;
      bun = on;
      uv = on;
    };
  };
}
