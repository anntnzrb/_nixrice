{
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.boot;
in
{
  config = {
    boot = {
      consoleLogLevel = 3;
      tmp.cleanOnBoot = true;
    };
  };
}
